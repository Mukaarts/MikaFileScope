// SparkleUpdater.swift
// MikaFileScope
//
// Sparkle auto-update wrapper for checking and installing updates.
// Swift 6.0 strict concurrency, macOS 14+
//
// Nur in der Direktvertriebs-Variante enthalten. Der Mac App Store erlaubt keinen
// eigenen Update-Mechanismus; dort übernimmt der Store die Aktualisierung.

#if !APPSTORE

import Foundation
@preconcurrency import Sparkle

/// Liefert die Feed-Adresse ausschließlich aus der signierten `Info.plist`.
///
/// Ohne dieses Delegate zieht Sparkle die Adresse auch aus den Benutzereinstellungen.
/// Die kann jeder Prozess im Nutzerkontext ohne besondere Rechte schreiben — ein
/// `defaults write lu.daumedia.mikafilescope SUFeedURL …` genügt, um den Update-Kanal
/// auf eine fremde Quelle umzubiegen (BUG-03 im Testbericht vom 2026-08-23).
private final class FeedURLProvider: NSObject, SPUUpdaterDelegate, @unchecked Sendable {
    func feedURLString(for updater: SPUUpdater) -> String? {
        Bundle.main.object(forInfoDictionaryKey: "SUFeedURL") as? String
    }
}

@MainActor
final class SparkleUpdater {
    private let updaterController: SPUStandardUpdaterController
    private let feedURLProvider: FeedURLProvider

    var canCheckForUpdates: Bool {
        updaterController.updater.canCheckForUpdates
    }

    var automaticallyChecksForUpdates: Bool {
        get { updaterController.updater.automaticallyChecksForUpdates }
        set { updaterController.updater.automaticallyChecksForUpdates = newValue }
    }

    init() {
        let provider = FeedURLProvider()
        self.feedURLProvider = provider
        self.updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: provider,
            userDriverDelegate: nil
        )
    }

    var lastUpdateCheckDate: Date? {
        updaterController.updater.lastUpdateCheckDate
    }

    func checkForUpdates() {
        updaterController.checkForUpdates(nil)
    }
}

#endif
