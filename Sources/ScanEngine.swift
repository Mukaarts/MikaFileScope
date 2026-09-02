// ScanEngine.swift
// MikaFileScope

import Foundation

struct DateBucket: Identifiable, Sendable {
    let id: String
    let label: String
    let fileCount: Int
    let totalBytes: Int64
    let sortIndex: Int
}

struct ScanResult: Sendable {
    let groups: [FileTypeGroup]
    let totalFiles: Int
    let totalSize: Int64
    let dateBuckets: [DateBucket]
    let fileURLs: [URL]
    /// Dateien, die beim Lesen fehlschlugen. Früher stillschweigend übersprungen —
    /// die Summen waren dann zu niedrig, ohne dass es jemand erfuhr.
    let unreadableCount: Int
}

@Observable
@MainActor
final class ScanEngine {
    var groups: [FileTypeGroup] = []
    var isScanning = false
    var scannedFolderURL: URL?
    var totalFiles: Int = 0
    var totalSize: Int64 = 0
    var errorMessage: String?
    var includeHidden: Bool = false
    var selectedCategory: FileCategory = .all
    var dateBuckets: [DateBucket] = []
    var scannedURLs: [URL] = []
    /// Zeitpunkt, zu dem der letzte Durchlauf endete. Der Export nennt ihn als
    /// `scannedAt` — zuvor stand dort der Zeitpunkt des Exports.
    var scannedAt: Date?

    /// Anzahl der Dateien, die nicht gelesen werden konnten (Rechte, Löschung während des Scans).
    var unreadableCount: Int = 0
    /// Fortschritt als Anzahl bereits erfasster Dateien. Der Gesamtumfang ist beim
    /// Durchlaufen nicht bekannt, deshalb eine Zählung statt eines Anteils.
    var scannedSoFar: Int = 0

    private var scanTask: Task<Void, Never>?
    /// Der Durchlauf im Hintergrund, getrennt festgehalten. Ein `Task.detached` erbt
    /// den Abbruch seines Erzeugers nicht — ohne eigene Referenz lief die Enumeration
    /// nach „Cancel" unbemerkt weiter, während die Oberfläche schon Ruhe meldete.
    private var arbeitsTask: Task<Result<ScanResult, Error>, Never>?

    /// Schlüssel des Security-Scoped Bookmarks des zuletzt gescannten Ordners.
    private static let bookmarkKey = "lastFolderBookmark"

    var filteredGroups: [FileTypeGroup] {
        guard selectedCategory != .all else { return groups }
        return groups.filter { selectedCategory.matches(ext: $0.ext) }
    }

    var filteredTotalFiles: Int {
        guard selectedCategory != .all else { return totalFiles }
        return filteredGroups.reduce(0) { $0 + $1.count }
    }

    var filteredTotalSize: Int64 {
        guard selectedCategory != .all else { return totalSize }
        return filteredGroups.reduce(0) { $0 + $1.totalBytes }
    }

    /// Die Dateien, die zur aktuellen Kategorie gehören. Grundlage für die
    /// Duplikatsuche, damit sie demselben Filter folgt wie alles Übrige.
    var filteredURLs: [URL] {
        guard selectedCategory != .all else { return scannedURLs }
        return scannedURLs.filter { selectedCategory.matches(ext: $0.pathExtension.lowercased()) }
    }

    // MARK: - Scannen

    func scan(folder url: URL) {
        // Ein laufender Durchlauf wird abgebrochen, bevor ein neuer beginnt. Vorher
        // konnten zwei Scans nebeneinander laufen und ihre Ergebnisse überschreiben.
        scanTask?.cancel()

        isScanning = true
        errorMessage = nil
        scannedFolderURL = url
        scannedSoFar = 0
        unreadableCount = 0
        // Ein neuer Ordner mit altem Filter zeigt sonst „keine Treffer", wo Daten sind.
        selectedCategory = .all

        storeBookmark(for: url)

        let folderURL = url
        let includeHidden = self.includeHidden
        scanTask = Task { [weak self] in
            // Der Fortschritt wandert über einen Stream aus dem Hintergrund heraus;
            // geschrieben wird er nur hier, auf dem Main Actor. Dasselbe Muster wie in
            // `DuplicateDetector.detect(urls:scopeRoot:)`. Zuvor blieb `scannedSoFar`
            // auf 0 stehen — `performScan` ist `nonisolated` und kam gar nicht daran.
            // Ein langer Durchlauf war dadurch von einer hängenden App nicht zu
            // unterscheiden.
            let (stream, continuation) = AsyncStream<Int>.makeStream()
            let arbeit = Task.detached {
                let ergebnis = Self.performScan(at: folderURL, includeHidden: includeHidden) { gezaehlt in
                    continuation.yield(gezaehlt)
                }
                continuation.finish()
                return ergebnis
            }
            self?.arbeitsTask = arbeit

            for await gezaehlt in stream {
                guard let self, !Task.isCancelled else { break }
                self.scannedSoFar = gezaehlt
            }

            let result = await arbeit.value
            guard !Task.isCancelled else { return }
            guard let self else { return }
            switch result {
            case .success(let data):
                self.groups = data.groups
                self.totalFiles = data.totalFiles
                self.totalSize = data.totalSize
                self.dateBuckets = data.dateBuckets
                self.scannedURLs = data.fileURLs
                self.unreadableCount = data.unreadableCount
                self.scannedAt = Date()
            case .failure(let error):
                self.errorMessage = error.localizedDescription
            }
            self.isScanning = false
        }
    }

    func rescan() {
        guard let url = scannedFolderURL else { return }
        scan(folder: url)
    }

    /// Bricht einen laufenden Durchlauf ab. Das bisherige Ergebnis bleibt stehen.
    func cancelScan() {
        scanTask?.cancel()
        // Der Hintergrund-Durchlauf muss ausdrücklich mit abgebrochen werden, sonst
        // enumeriert er weiter, bis der Ordner zu Ende gelesen ist.
        arbeitsTask?.cancel()
        scanTask = nil
        arbeitsTask = nil
        isScanning = false
    }

    func reset() {
        cancelScan()
        groups = []
        scannedFolderURL = nil
        totalFiles = 0
        totalSize = 0
        errorMessage = nil
        dateBuckets = []
        scannedURLs = []
        scannedAt = nil
        unreadableCount = 0
        scannedSoFar = 0
        selectedCategory = .all
        UserDefaults.standard.removeObject(forKey: Self.bookmarkKey)
    }

    // MARK: - Zuletzt gescannter Ordner

    /// Legt ein Security-Scoped Bookmark ab, damit „Rescan" einen Neustart überlebt —
    /// in der Sandbox der einzige Weg, den Zugriff über die Sitzung hinaus zu behalten.
    private func storeBookmark(for url: URL) {
        guard let data = try? url.bookmarkData(
            options: .withSecurityScope,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        ) else { return }
        UserDefaults.standard.set(data, forKey: Self.bookmarkKey)
    }

    /// Stellt den zuletzt gescannten Ordner wieder her, ohne ihn zu scannen.
    /// Ergebnis: „Rescan" ist nach dem Start verfügbar.
    func restoreLastFolder() {
        guard let data = UserDefaults.standard.data(forKey: Self.bookmarkKey) else { return }
        var stale = false
        guard let url = try? URL(
            resolvingBookmarkData: data,
            options: .withSecurityScope,
            relativeTo: nil,
            bookmarkDataIsStale: &stale
        ), !stale else {
            UserDefaults.standard.removeObject(forKey: Self.bookmarkKey)
            return
        }
        scannedFolderURL = url
    }

    // MARK: - Durchlauf

    private nonisolated static func performScan(
        at url: URL,
        includeHidden: Bool = false,
        onProgress: (Int) -> Void = { _ in }
    ) -> Result<ScanResult, Error> {
        let accessing = url.startAccessingSecurityScopedResource()
        defer {
            if accessing { url.stopAccessingSecurityScopedResource() }
        }

        let keys: [URLResourceKey] = [.fileSizeKey, .isDirectoryKey, .contentModificationDateKey, .isSymbolicLinkKey]
        var options: FileManager.DirectoryEnumerationOptions = [.skipsPackageDescendants]
        if !includeHidden { options.insert(.skipsHiddenFiles) }

        guard let enumerator = FileManager.default.enumerator(
            at: url,
            includingPropertiesForKeys: keys,
            options: options
        ) else {
            // Der häufigste Grund ist eine verweigerte Zustimmung, nicht ein defekter
            // Pfad. Die Meldung muss den Weg zurück nennen, sonst wirkt die App kaputt.
            return .failure(NSError(
                domain: "MikaFileScope",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey:
                    "Could not read \u{201C}\(url.lastPathComponent)\u{201D}. "
                    + "macOS may have denied access to this folder. You can grant it in "
                    + "System Settings \u{203A} Privacy & Security \u{203A} Files and Folders."]
            ))
        }

        var dict: [String: (count: Int, bytes: Int64)] = [:]
        var dateBucketDict: [String: (count: Int, bytes: Int64, sortIndex: Int)] = [:]
        var fileURLs: [URL] = []
        var totalFiles = 0
        var totalSize: Int64 = 0
        var unreadable = 0

        // Ein Bezugszeitpunkt für den gesamten Durchlauf. Vorher wurde er je Datei neu
        // geholt; ein Scan über Mitternacht konnte gleich alte Dateien verschieden einordnen.
        let now = Date()
        let calendar = Calendar.current

        for case let fileURL as URL in enumerator {
            if Task.isCancelled { break }
            do {
                let resourceValues = try fileURL.resourceValues(forKeys: Set(keys))
                if resourceValues.isDirectory == true { continue }
                // Ein Verweis zählt nicht als eigene Datei — sein Ziel wird ohnehin
                // erfasst, wenn es im gescannten Bereich liegt.
                if resourceValues.isSymbolicLink == true { continue }

                let fileSize = Int64(resourceValues.fileSize ?? 0)
                let ext = fileURL.pathExtension.lowercased()

                totalFiles += 1
                totalSize += fileSize
                fileURLs.append(fileURL)

                // Nicht bei jeder Datei: Bei hunderttausenden Einträgen kostet der
                // Stream sonst mehr als der Scan selbst.
                if totalFiles % 200 == 0 { onProgress(totalFiles) }

                dict[ext, default: (count: 0, bytes: 0)].count += 1
                dict[ext]!.bytes += fileSize

                if let modDate = resourceValues.contentModificationDate {
                    let bucket = dateBucketKey(for: modDate, now: now, calendar: calendar)
                    dateBucketDict[bucket.key, default: (count: 0, bytes: 0, sortIndex: bucket.sortIndex)].count += 1
                    dateBucketDict[bucket.key]!.bytes += fileSize
                }
            } catch {
                unreadable += 1
                continue
            }
        }

        onProgress(totalFiles)

        let groups = dict.map { ext, data in
            FileTypeGroup(ext: ext, count: data.count, totalBytes: data.bytes)
        }.sorted { $0.count > $1.count }

        let dateBuckets = dateBucketDict.map { key, data in
            DateBucket(id: key, label: key, fileCount: data.count, totalBytes: data.bytes, sortIndex: data.sortIndex)
        }.sorted { $0.sortIndex < $1.sortIndex }

        return .success(ScanResult(
            groups: groups,
            totalFiles: totalFiles,
            totalSize: totalSize,
            dateBuckets: dateBuckets,
            fileURLs: fileURLs,
            unreadableCount: unreadable
        ))
    }

    /// Ordnet ein Änderungsdatum einem Zeitfenster zu.
    /// `now` wird übergeben, damit ein ganzer Durchlauf denselben Bezugspunkt hat.
    nonisolated static func dateBucketKey(
        for date: Date,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> (key: String, sortIndex: Int) {
        let days = calendar.dateComponents([.day], from: date, to: now).day ?? Int.max

        switch days {
        case ..<0:     return ("Future", 0)
        case 0:        return ("Today", 1)
        case 1...7:    return ("Past Week", 2)
        case 8...30:   return ("Past Month", 3)
        case 31...90:  return ("Past 3 Months", 4)
        case 91...365: return ("Past Year", 5)
        default:       return ("Older", 6)
        }
    }
}
