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

    func scan(folder url: URL) {
        isScanning = true
        errorMessage = nil
        scannedFolderURL = url

        let folderURL = url
        let includeHidden = self.includeHidden
        Task.detached {
            let result = Self.performScan(at: folderURL, includeHidden: includeHidden)
            await MainActor.run { [weak self] in
                guard let self else { return }
                switch result {
                case .success(let data):
                    self.groups = data.groups
                    self.totalFiles = data.totalFiles
                    self.totalSize = data.totalSize
                    self.dateBuckets = data.dateBuckets
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
                self.isScanning = false
            }
        }
    }

    func rescan() {
        guard let url = scannedFolderURL else { return }
        scan(folder: url)
    }

    func reset() {
        groups = []
        isScanning = false
        scannedFolderURL = nil
        totalFiles = 0
        totalSize = 0
        errorMessage = nil
        dateBuckets = []
    }

    private nonisolated static func performScan(at url: URL, includeHidden: Bool = false) -> Result<ScanResult, Error> {
        let accessing = url.startAccessingSecurityScopedResource()
        defer {
            if accessing { url.stopAccessingSecurityScopedResource() }
        }

        let keys: [URLResourceKey] = [.fileSizeKey, .isDirectoryKey, .contentModificationDateKey]
        let options: FileManager.DirectoryEnumerationOptions = includeHidden ? [] : [.skipsHiddenFiles]
        guard let enumerator = FileManager.default.enumerator(
            at: url,
            includingPropertiesForKeys: keys,
            options: options
        ) else {
            return .failure(NSError(
                domain: "MikaFileScope",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Cannot access folder: \(url.path)"]
            ))
        }

        var dict: [String: (count: Int, bytes: Int64)] = [:]
        var dateBucketDict: [String: (count: Int, bytes: Int64, sortIndex: Int)] = [:]
        var totalFiles = 0
        var totalSize: Int64 = 0

        for case let fileURL as URL in enumerator {
            do {
                let resourceValues = try fileURL.resourceValues(forKeys: Set(keys))
                if resourceValues.isDirectory == true { continue }

                let fileSize = Int64(resourceValues.fileSize ?? 0)
                let ext = fileURL.pathExtension.lowercased()

                totalFiles += 1
                totalSize += fileSize

                if var entry = dict[ext] {
                    entry.count += 1
                    entry.bytes += fileSize
                    dict[ext] = entry
                } else {
                    dict[ext] = (count: 1, bytes: fileSize)
                }

                if let modDate = resourceValues.contentModificationDate {
                    let bucket = dateBucketKey(for: modDate)
                    if var entry = dateBucketDict[bucket.key] {
                        entry.count += 1
                        entry.bytes += fileSize
                        dateBucketDict[bucket.key] = entry
                    } else {
                        dateBucketDict[bucket.key] = (count: 1, bytes: fileSize, sortIndex: bucket.sortIndex)
                    }
                }
            } catch {
                continue
            }
        }

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
            dateBuckets: dateBuckets
        ))
    }

    private nonisolated static func dateBucketKey(for date: Date) -> (key: String, sortIndex: Int) {
        let now = Date()
        let calendar = Calendar.current
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
