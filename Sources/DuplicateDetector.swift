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

    func detect(urls: [URL]) {
        guard !urls.isEmpty else { return }
        isDetecting = true
        progress = 0
        duplicateGroups = []
        totalWastedBytes = 0

        let fileURLs = urls
        Task {
            let result = await Task.detached {
                Self.findDuplicates(urls: fileURLs)
            }.value
            self.duplicateGroups = result.sorted { $0.wastedBytes > $1.wastedBytes }
            self.totalWastedBytes = result.reduce(0) { $0 + $1.wastedBytes }
            self.isDetecting = false
            self.progress = 1.0
        }
    }

    private nonisolated static func findDuplicates(urls: [URL]) -> [DuplicateGroup] {
        // Phase 1: Group by file size (skip files < 1 KB)
        var sizeGroups: [Int64: [URL]] = [:]
        for url in urls {
            if let size = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                let size64 = Int64(size)
                guard size64 >= 1024 else { continue }
                sizeGroups[size64, default: []].append(url)
            }
        }

        let candidates = sizeGroups.filter { $0.value.count >= 2 }

        // Phase 2: SHA-256 hash files of the same size
        var hashGroups: [String: (size: Int64, urls: [URL])] = [:]

        for (size, fileURLs) in candidates {
            for fileURL in fileURLs {
                if let hash = sha256Hash(of: fileURL) {
                    if var group = hashGroups[hash] {
                        group.urls.append(fileURL)
                        hashGroups[hash] = group
                    } else {
                        hashGroups[hash] = (size: size, urls: [fileURL])
                    }
                }
            }
        }

        return hashGroups
            .filter { $0.value.urls.count >= 2 }
            .map { DuplicateGroup(hash: $0.key, fileSize: $0.value.size, urls: $0.value.urls) }
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
