// DuplicateDetector.swift
// MikaFileScope

import CryptoKit
import Foundation

struct DuplicateGroup: Identifiable, Sendable {
    let id = UUID()
    let hash: String
    let fileSize: Int64
    let urls: [URL]

    var formattedSize: String {
        ByteCountFormatter().string(fromByteCount: fileSize)
    }

    var wastedBytes: Int64 {
        fileSize * Int64(urls.count - 1)
    }
}

@Observable
@MainActor
final class DuplicateDetector {
    var duplicateGroups: [DuplicateGroup] = []
    var isDetecting = false
    var progress: Double = 0
    var totalWastedBytes: Int64 = 0

    /// Anzahl der Dateien, die wegen der Größenschwelle nicht geprüft wurden.
    /// Sichtbar zu machen, damit „keine Duplikate" nicht heißt „nicht gesucht".
    var skippedTooSmall: Int = 0
    /// Dateien, die sich nicht öffnen ließen. Ohne diese Zahl war ein verweigerter
    /// Zugriff von „es gibt keine Duplikate" nicht zu unterscheiden.
    var unreadable: Int = 0
    /// Untergrenze für den Vergleich. Kleinere Dateien erzeugen Massen belangloser Treffer.
    nonisolated static let minimumSize: Int64 = 1024

    private var task: Task<Void, Never>?
    /// Der Suchlauf im Hintergrund. Getrennt festgehalten, weil ein `Task.detached`
    /// den Abbruch seines Erzeugers nicht erbt — `Task.isCancelled` darin blieb sonst
    /// dauerhaft falsch, und „Cancel" beendete nur die Anzeige, nicht die Arbeit.
    private var arbeitsTask: Task<(groups: [DuplicateGroup], skipped: Int, unreadable: Int), Never>?

    /// - Parameter scopeRoot: Der gescannte Ordner. In der Sandbox zwingend: Die
    ///   übergebenen URLs stammen aus dem Scan, dessen Zugriff `ScanEngine.performScan`
    ///   per `defer` längst wieder geschlossen hat. Ohne erneuten Security Scope schlug
    ///   hier jedes `FileHandle(forReadingFrom:)` still fehl — die Suche meldete dann
    ///   „keine Duplikate", obwohl sie keine einzige Datei gelesen hatte.
    func detect(urls: [URL], scopeRoot: URL? = nil) {
        guard !urls.isEmpty else { return }
        task?.cancel()
        arbeitsTask?.cancel()
        isDetecting = true
        progress = 0
        duplicateGroups = []
        totalWastedBytes = 0
        skippedTooSmall = 0
        unreadable = 0

        let fileURLs = urls
        let wurzel = scopeRoot
        task = Task { [weak self] in
            // Der Hintergrund-Task berührt `self` nicht: Er meldet Fortschritt über
            // den Stream und gibt sein Ergebnis zurück. Nur der äußere Task — der auf
            // dem Main Actor läuft — schreibt in den Zustand. Andernfalls geriete
            // MainActor-isoliertes `self` in eine nebenläufige Ausführung.
            let (stream, continuation) = AsyncStream<Double>.makeStream()
            let arbeit = Task.detached {
                let zugriff = wurzel?.startAccessingSecurityScopedResource() ?? false
                defer { if zugriff { wurzel?.stopAccessingSecurityScopedResource() } }

                let ergebnis = Self.findDuplicates(urls: fileURLs) { done, total in
                    continuation.yield(total > 0 ? Double(done) / Double(total) : 0)
                }
                continuation.finish()
                return ergebnis
            }
            self?.arbeitsTask = arbeit

            for await p in stream {
                guard let self, !Task.isCancelled else { break }
                self.progress = p
            }

            let ergebnis = await arbeit.value
            guard let self, !Task.isCancelled else { return }
            self.duplicateGroups = ergebnis.groups.sorted { $0.wastedBytes > $1.wastedBytes }
            self.totalWastedBytes = ergebnis.groups.reduce(0) { $0 + $1.wastedBytes }
            self.skippedTooSmall = ergebnis.skipped
            self.unreadable = ergebnis.unreadable
            self.isDetecting = false
            self.progress = 1.0
        }
    }

    /// Bricht einen laufenden Suchlauf ab.
    func cancel() {
        task?.cancel()
        // Der Suchlauf selbst muss ausdrücklich mit abgebrochen werden, sonst hasht er
        // bis zur letzten Datei weiter.
        arbeitsTask?.cancel()
        task = nil
        arbeitsTask = nil
        isDetecting = false
    }

    private nonisolated static func findDuplicates(
        urls: [URL],
        onProgress: (Int, Int) -> Void
    ) -> (groups: [DuplicateGroup], skipped: Int, unreadable: Int) {
        // Stufe 1: nach Größe gruppieren. Dateien unter der Schwelle bleiben außen vor,
        // werden aber gezählt, damit die Oberfläche es benennen kann.
        var sizeGroups: [Int64: [URL]] = [:]
        var skipped = 0
        var unreadable = 0
        // Dateisystem-Identität (Gerät + Inode): Hardlinks zeigen auf dieselben Daten.
        // Sie zu löschen gibt keinen Platz frei — sie dürfen nicht als Duplikat gelten.
        var seenInodes = Set<String>()

        for url in urls {
            guard let v = try? url.resourceValues(forKeys: [.fileSizeKey, .fileResourceIdentifierKey])
            else { continue }
            let size64 = Int64(v.fileSize ?? 0)
            guard size64 >= minimumSize else { skipped += 1; continue }
            if let ident = v.fileResourceIdentifier {
                let key = String(describing: ident)
                if seenInodes.contains(key) { continue }
                seenInodes.insert(key)
            }
            sizeGroups[size64, default: []].append(url)
        }

        let candidates = sizeGroups.filter { $0.value.count >= 2 }
        let total = candidates.reduce(0) { $0 + $1.value.count }
        var done = 0

        // Stufe 2: SHA-256 für Dateien gleicher Größe
        var hashGroups: [String: (size: Int64, urls: [URL])] = [:]
        for (size, fileURLs) in candidates {
            for fileURL in fileURLs {
                if Task.isCancelled { return (groups: [], skipped: skipped, unreadable: unreadable) }
                if let hash = sha256Hash(of: fileURL) {
                    if var group = hashGroups[hash] {
                        group.urls.append(fileURL)
                        hashGroups[hash] = group
                    } else {
                        hashGroups[hash] = (size: size, urls: [fileURL])
                    }
                } else {
                    unreadable += 1
                }
                done += 1
                onProgress(done, total)
            }
        }

        let groups = hashGroups
            .filter { $0.value.urls.count >= 2 }
            .map { DuplicateGroup(hash: $0.key, fileSize: $0.value.size, urls: $0.value.urls) }
        return (groups: groups, skipped: skipped, unreadable: unreadable)
    }

    /// Streaming SHA-256 hash using 1 MB chunks to avoid loading large files into memory
    private nonisolated static func sha256Hash(of url: URL) -> String? {
        guard let handle = try? FileHandle(forReadingFrom: url) else { return nil }
        defer { try? handle.close() }

        var hasher = SHA256()
        let chunkSize = 1024 * 1024 // 1 MB

        while autoreleasepool(invoking: {
            let data = handle.readData(ofLength: chunkSize)
            guard !data.isEmpty else { return false }
            hasher.update(data: data)
            return true
        }) {}

        let digest = hasher.finalize()
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
