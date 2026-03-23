// ScanEngine.swift
// MikaFileScope

import Foundation

struct ScanResult: Sendable {
    let groups: [FileTypeGroup]
    let totalFiles: Int
    let totalSize: Int64
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

    func scan(folder url: URL) {
        isScanning = true
        errorMessage = nil
        scannedFolderURL = url

        let folderURL = url
        Task.detached {
            let result = Self.performScan(at: folderURL)
            await MainActor.run { [weak self] in
                guard let self else { return }
                switch result {
                case .success(let data):
                    self.groups = data.groups
                    self.totalFiles = data.totalFiles
                    self.totalSize = data.totalSize
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
    }

    private nonisolated static func performScan(at url: URL) -> Result<ScanResult, Error> {
        let accessing = url.startAccessingSecurityScopedResource()
        defer {
            if accessing { url.stopAccessingSecurityScopedResource() }
        }

        let keys: [URLResourceKey] = [.fileSizeKey, .isDirectoryKey]
        guard let enumerator = FileManager.default.enumerator(
            at: url,
            includingPropertiesForKeys: keys,
            options: [.skipsHiddenFiles]
        ) else {
            return .failure(NSError(
                domain: "MikaFileScope",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Cannot access folder: \(url.path)"]
            ))
        }

        var dict: [String: (count: Int, bytes: Int64)] = [:]
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
            } catch {
                continue
            }
        }

        let groups = dict.map { ext, data in
            FileTypeGroup(ext: ext, count: data.count, totalBytes: data.bytes)
        }.sorted { $0.count > $1.count }

        return .success(ScanResult(
            groups: groups,
            totalFiles: totalFiles,
            totalSize: totalSize
        ))
    }
}
