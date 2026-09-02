// MikaFileScopeApp.swift
// MikaFileScope

import SwiftUI

@main
struct MikaFileScopeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @AppStorage(AppStorageKeys.showMenubar) private var showMenubar = false

    var body: some Scene {
        WindowGroup {
            ContentView(engine: appDelegate.engine)
        }
        .windowResizability(.contentMinSize)
        .defaultSize(width: 900, height: 650)
        .commands {
            CommandGroup(after: .newItem) {
                // Bindet `ScanEngine.reset()` an die Oberfläche. Zuvor war die Methode
                // vorhanden, aber ohne Aufrufer - es gab keinen Weg zurück in den
                // Leerzustand, und das gespeicherte Bookmark blieb liegen.
                Button("Reset") {
                    appDelegate.engine.reset()
                }
                .keyboardShortcut("k", modifiers: [.command, .shift])
                .disabled(appDelegate.engine.scannedFolderURL == nil)
            }

            // Zweiter Weg zum Export, unabhängig von der Toolbar. Im App Review am
            // 2026-09-01 blieb das Toolbar-Menü ohne Wirkung, und es gab keinen
            // Ausweg — ein Menübefehl mit Tastenkürzel ist zudem die Konvention.
            CommandGroup(after: .saveItem) {
                Button("Export as CSV\u{2026}") {
                    let engine = appDelegate.engine
                    ExportManager.exportCSV(
                        groups: engine.filteredGroups,
                        totalSize: engine.filteredTotalSize,
                        folderURL: engine.scannedFolderURL
                    )
                }
                .keyboardShortcut("e", modifiers: .command)
                .disabled(appDelegate.engine.filteredGroups.isEmpty)

                Button("Export as JSON\u{2026}") {
                    let engine = appDelegate.engine
                    ExportManager.exportJSON(
                        groups: engine.filteredGroups,
                        totalFiles: engine.filteredTotalFiles,
                        totalSize: engine.filteredTotalSize,
                        folderURL: engine.scannedFolderURL,
                        scannedAt: engine.scannedAt
                    )
                }
                .keyboardShortcut("e", modifiers: [.command, .shift])
                .disabled(appDelegate.engine.filteredGroups.isEmpty)
            }
            #if !APPSTORE
            // Im Store übernimmt Apple die Aktualisierung; ein eigener Menübefehl
            // wäre dort unzulässig.
            CommandGroup(after: .appInfo) {
                Button("Check for Updates...") {
                    appDelegate.sparkleUpdater.checkForUpdates()
                }
                .disabled(!appDelegate.sparkleUpdater.canCheckForUpdates)
            }
            #endif
        }

        MenuBarExtra("FileScope", systemImage: "doc.viewfinder", isInserted: $showMenubar) {
            MenubarPopoverView(engine: appDelegate.engine)
        }
        .menuBarExtraStyle(.window)
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let engine = ScanEngine()
    #if !APPSTORE
    let sparkleUpdater = SparkleUpdater()
    #endif

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Stellt den zuletzt gescannten Ordner wieder her, damit „Rescan" einen
        // Neustart überlebt. Gescannt wird dabei nicht — nur der Zugriff steht wieder.
        engine.restoreLastFolder()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        !UserDefaults.standard.bool(forKey: AppStorageKeys.showMenubar)
    }
}
