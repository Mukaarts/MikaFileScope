// MikaFileScopeApp.swift
// MikaFileScope

import SwiftUI

@main
struct MikaFileScopeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @AppStorage("showMenubar") private var showMenubar = false

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
                Button("Zurücksetzen") {
                    appDelegate.engine.reset()
                }
                .keyboardShortcut("k", modifiers: [.command, .shift])
                .disabled(appDelegate.engine.scannedFolderURL == nil)
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
