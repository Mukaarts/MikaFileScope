// FileTypeGroup.swift
// MikaFileScope

import Foundation

struct FileTypeGroup: Identifiable, Hashable, Sendable {
    let id = UUID()
    let ext: String
    var count: Int
    var totalBytes: Int64

    var displayExt: String {
        ext.isEmpty ? "(no extension)" : ".\(ext.uppercased())"
    }

    var formattedSize: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: totalBytes)
    }

    func percentage(of totalSize: Int64) -> Double {
        guard totalSize > 0 else { return 0 }
        return (Double(totalBytes) / Double(totalSize)) * 100.0
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: FileTypeGroup, rhs: FileTypeGroup) -> Bool {
        lhs.id == rhs.id
    }
}
