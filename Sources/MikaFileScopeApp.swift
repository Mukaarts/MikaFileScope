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

        MenuBarExtra("FileScope", systemImage: "doc.viewfinder", isInserted: $showMenubar) {
            MenubarPopoverView(engine: appDelegate.engine)
        }
        .menuBarExtraStyle(.window)
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let engine = ScanEngine()

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        !UserDefaults.standard.bool(forKey: "showMenubar")
    }
}
