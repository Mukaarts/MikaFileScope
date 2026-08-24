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

    static func exportJSON(groups: [FileTypeGroup], totalFiles: Int, totalSize: Int64, folderURL: URL?, scannedAt: Date?) {
        guard let content = generateJSON(groups: groups, totalFiles: totalFiles, totalSize: totalSize,
                                         folderURL: folderURL, scannedAt: scannedAt) else {
            // Zuvor wurde in diesem Fall "{}" gespeichert — der Nutzer hielt eine leere
            // Datei für einen gelungenen Export.
            showError("Der Export konnte nicht erzeugt werden.")
            return
        }
        let folderName = folderURL?.lastPathComponent ?? "scan"
        save(content: content, defaultName: "FileScope_\(folderName).json", allowedType: .json)
    }

    // MARK: - CSV

    static func generateCSV(groups: [FileTypeGroup], totalSize: Int64) -> String {
        var csv = "Extension,Count,Size (Bytes),Size (Human),Percentage\n"
        for group in groups {
            let pct = String(format: "%.1f", group.percentage(of: totalSize))
            let ext = group.displayExt.replacingOccurrences(of: "\"", with: "\"\"")
            csv += "\"\(ext)\",\(group.count),\(group.totalBytes),\"\(group.formattedSize)\",\(pct)%\n"
        }
        return csv
    }

    // MARK: - JSON

    static func generateJSON(groups: [FileTypeGroup], totalFiles: Int, totalSize: Int64,
                             folderURL: URL?, scannedAt: Date?) -> String? {
        let formatter = ISO8601DateFormatter()

        let groupEntries = groups.map { group -> [String: Any] in
            [
                "extension": group.ext.isEmpty ? "(no extension)" : group.ext,
                "count": group.count,
                "sizeBytes": group.totalBytes,
                "sizeHuman": group.formattedSize,
                // Als Dezimalzahl, nicht als Double: `round(x * 10) / 10` liefert den
                // nächstliegenden Double zu 5.1 — und JSONSerialization schrieb den in
                // voller Genauigkeit als 5.0999999999999996 aus.
                "percentage": decimalPercentage(group.percentage(of: totalSize))
            ]
        }

        let root: [String: Any] = [
            "scannedFolder": folderURL?.path ?? "",
            // Zeitpunkt des Scans, nicht des Exports.
            "scannedAt": scannedAt.map { formatter.string(from: $0) } ?? "",
            "totalFiles": totalFiles,
            "totalSizeBytes": totalSize,
            "groups": groupEntries
        ]

        guard JSONSerialization.isValidJSONObject(root),
              let data = try? JSONSerialization.data(withJSONObject: root, options: [.prettyPrinted, .sortedKeys]),
              let json = String(data: data, encoding: .utf8) else {
            return nil
        }
        return json
    }

    /// Anteil mit genau einer Nachkommastelle, ohne Gleitkomma-Artefakte in der Ausgabe.
    static func decimalPercentage(_ value: Double) -> NSDecimalNumber {
        NSDecimalNumber(string: String(format: "%.1f", value))
    }

    private static func showError(_ text: String) {
        let alert = NSAlert()
        alert.messageText = "Export Failed"
        alert.informativeText = text
        alert.alertStyle = .warning
        alert.runModal()
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
            showError(error.localizedDescription)
        }
    }
}
