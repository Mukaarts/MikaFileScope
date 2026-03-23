// ExportManager.swift
// MikaFileScope

import AppKit
import Foundation
import UniformTypeIdentifiers

@MainActor
enum ExportManager {

    static func exportCSV(groups: [FileTypeGroup], totalSize: Int64, folderURL: URL?) {
        let content = generateCSV(groups: groups, totalSize: totalSize)
        let folderName = folderURL?.lastPathComponent ?? "scan"
        save(content: content, defaultName: "FileScope_\(folderName).csv", allowedType: .commaSeparatedText)
    }

    static func exportJSON(groups: [FileTypeGroup], totalFiles: Int, totalSize: Int64, folderURL: URL?) {
        let content = generateJSON(groups: groups, totalFiles: totalFiles, totalSize: totalSize, folderURL: folderURL)
        let folderName = folderURL?.lastPathComponent ?? "scan"
        save(content: content, defaultName: "FileScope_\(folderName).json", allowedType: .json)
    }

    // MARK: - CSV

    private static func generateCSV(groups: [FileTypeGroup], totalSize: Int64) -> String {
        var csv = "Extension,Count,Size (Bytes),Size (Human),Percentage\n"
        for group in groups {
            let pct = String(format: "%.1f", group.percentage(of: totalSize))
            let ext = group.displayExt.replacingOccurrences(of: "\"", with: "\"\"")
            csv += "\"\(ext)\",\(group.count),\(group.totalBytes),\"\(group.formattedSize)\",\(pct)%\n"
        }
        return csv
    }

    // MARK: - JSON

    private static func generateJSON(groups: [FileTypeGroup], totalFiles: Int, totalSize: Int64, folderURL: URL?) -> String {
        let formatter = ISO8601DateFormatter()
        let now = formatter.string(from: Date())

        let groupEntries = groups.map { group -> [String: Any] in
            [
                "extension": group.ext.isEmpty ? "(no extension)" : group.ext,
                "count": group.count,
                "sizeBytes": group.totalBytes,
                "sizeHuman": group.formattedSize,
                "percentage": round(group.percentage(of: totalSize) * 10) / 10
            ]
        }

        let root: [String: Any] = [
            "scannedFolder": folderURL?.path ?? "",
            "scannedAt": now,
            "totalFiles": totalFiles,
            "totalSizeBytes": totalSize,
            "groups": groupEntries
        ]

        guard let data = try? JSONSerialization.data(withJSONObject: root, options: [.prettyPrinted, .sortedKeys]),
              let json = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        return json
    }

    // MARK: - Save

    private static func save(content: String, defaultName: String, allowedType: UTType) {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = defaultName
        panel.allowedContentTypes = [allowedType]

        guard panel.runModal() == .OK, let url = panel.url else { return }

        do {
            try content.write(to: url, atomically: true, encoding: .utf8)
        } catch {
            let alert = NSAlert()
            alert.messageText = "Export Failed"
            alert.informativeText = error.localizedDescription
            alert.alertStyle = .warning
            alert.runModal()
        }
    }
}
