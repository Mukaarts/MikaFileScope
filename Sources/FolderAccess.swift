// FolderAccess.swift
// MikaFileScope
//
// Ordnerauswahl und die einmalige Erklärung davor — an einer Stelle.
//
// Warum zusammen: `ContentView` und `MenubarPopoverView` trugen bis 2.1.1 zwei
// zeichengleiche Kopien von `chooseFolder()`. Als die Erklärung dazukam, hätte
// jede Änderung an beiden Orten nachgezogen werden müssen.
//
// Warum es die Erklärung überhaupt gibt: Ein Scan über den Benutzerordner läuft
// rekursiv durch Schreibtisch, Dokumente und Downloads. macOS fragt dort für jeden
// Ordner einzeln nach Zustimmung. Diese Dialoge kommen vom System, nicht von der
// App — ohne Vorankündigung wirken sie zusammenhanglos. Genau das hat der App
// Review am 2026-09-01 beanstandet (5.1.1(ii)).

import AppKit
import Foundation

/// Der Wortlaut der Erklärung. Als eine Quelle gehalten, weil derselbe Text im
/// Fenster als Blatt und im Menüleisten-Popover als Hinweisfenster erscheint.
enum AccessIntro {
    static let title = "Before the first scan"

    static let subtitle =
        "Mika+FileScope measures how your storage is used. Here is exactly what that involves."

    static let points: [(symbol: String, headline: String, detail: String)] = [
        (
            "lock.shield",
            "macOS will ask for permission",
            "For the Desktop, Documents and Downloads folders, macOS asks separately before "
            + "anything is read. Those prompts come from the system, not from this app."
        ),
        (
            "doc.text.magnifyingglass",
            "Only names, sizes and dates",
            "A scan reads file names, sizes and modification dates. That is all it needs to "
            + "group your files by type and show where the space went."
        ),
        (
            "number",
            "Contents only for duplicate search",
            "File contents are read solely when you start a duplicate search, to compute a "
            + "checksum. Nothing is stored from them."
        ),
        (
            "hand.raised",
            "Nothing is changed or uploaded",
            "Files are never moved, renamed, changed or deleted. Results stay on this Mac; "
            + "exports are written only where you point the save dialog."
        )
    ]

    /// Derselbe Inhalt als Fließtext, für das Hinweisfenster im Menüleisten-Popover.
    static var plainText: String {
        points.map { "\u{2022} \($0.headline): \($0.detail)" }.joined(separator: "\n\n")
    }
}

@MainActor
enum FolderPicker {

    /// Öffnet die Ordnerauswahl und startet bei Bestätigung den Scan.
    static func choose(engine: ScanEngine) {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Scan Folder"
        // Der Dialog ist die letzte Stelle vor den Systemabfragen, an der die App
        // selbst noch sprechen kann.
        panel.message = "Choose a folder to scan. Mika+FileScope reads file names, sizes and "
            + "dates only — nothing is moved, changed or uploaded."

        if panel.runModal() == .OK, let url = panel.url {
            engine.scan(folder: url)
        }
    }

    /// Zeigt die Erklärung als eigenes Fenster und meldet, ob fortgefahren werden soll.
    /// Für das Menüleisten-Popover, in dem sich kein Blatt darstellen lässt.
    static func confirmIntroModally() -> Bool {
        let alert = NSAlert()
        alert.messageText = AccessIntro.title
        alert.informativeText = AccessIntro.subtitle + "\n\n" + AccessIntro.plainText
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Choose Folder\u{2026}")
        alert.addButton(withTitle: "Cancel")
        return alert.runModal() == .alertFirstButtonReturn
    }
}
