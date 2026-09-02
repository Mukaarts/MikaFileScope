// BundleConfigTests.swift
// Prüft Resources/Info.plist und die Store-Entitlements auf das, woran die
// Einreichung vom 2026-09-01 gescheitert ist.
//
// Beide Beanstandungen waren am Bundle ablesbar, bevor die App überhaupt startete:
// keine einzige Zweckbeschreibung (5.1.1(ii)) und ein Entitlement, das dem
// Speichern-Dialog das Schreibrecht verweigerte (2.1(a)). Genau das sichern diese
// Tests ab — sie brauchen weder Netz noch eine laufende App.

import XCTest

final class BundleConfigTests: XCTestCase {

    // Projektwurzel aus dem Pfad dieser Datei ableiten — unabhängig vom Arbeitsverzeichnis.
    private var projectRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()   // BundleConfigTests
            .deletingLastPathComponent()   // Tests
            .deletingLastPathComponent()   // Projektwurzel
    }

    private func plist(at pfad: String) throws -> [String: Any] {
        let url = projectRoot.appendingPathComponent(pfad)
        let data = try Data(contentsOf: url)
        guard let dict = try PropertyListSerialization
            .propertyList(from: data, format: nil) as? [String: Any] else {
            throw XCTSkip("\(pfad) nicht lesbar")
        }
        return dict
    }

    private var infoPlist: [String: Any] {
        get throws { try plist(at: "Resources/Info.plist") }
    }

    private var storeEntitlements: [String: Any] {
        get throws { try plist(at: "Resources/MikaFileScope-AppStore.entitlements") }
    }

    /// Die Ordner, in die ein Scan über den Benutzerordner zwangsläufig läuft, plus
    /// die Datenträger und Cloud-Ordner, die ausdrücklich als Anwendungsfall gelten.
    private static let zweckbeschreibungen = [
        "NSDesktopFolderUsageDescription",
        "NSDocumentsFolderUsageDescription",
        "NSDownloadsFolderUsageDescription",
        "NSRemovableVolumesUsageDescription",
        "NSNetworkVolumesUsageDescription",
        "NSFileProviderDomainUsageDescription"
    ]

    // MARK: - 5.1.1(ii) · Zweckbeschreibungen

    /// `FileManager.enumerator` läuft rekursiv. Wer den Benutzerordner wählt, trifft
    /// Schreibtisch, Dokumente und Downloads — fehlt der Schlüssel, erscheint der
    /// Systemdialog ohne jeden Text.
    func test_5_1_1_alleZweckbeschreibungenSindVorhanden() throws {
        let plist = try infoPlist
        for schluessel in Self.zweckbeschreibungen {
            let text = plist[schluessel] as? String
            XCTAssertNotNil(
                text,
                "\(schluessel) fehlt. Ohne diesen Schlüssel zeigt macOS den "
                + "Zustimmungsdialog ohne Erklärung — Ablehnungsgrund 5.1.1(ii)."
            )
            XCTAssertFalse(text?.isEmpty ?? true, "\(schluessel) ist leer")
        }
    }

    /// Apple verlangt eine vollständige Beschreibung, in der Regel mit Beispiel.
    /// Ein Halbsatz genügt nicht.
    func test_5_1_1_jedeBeschreibungIstAussagekraeftig() throws {
        let plist = try infoPlist
        for schluessel in Self.zweckbeschreibungen {
            guard let text = plist[schluessel] as? String else { continue }
            XCTAssertGreaterThan(
                text.count, 80,
                "\(schluessel) ist mit \(text.count) Zeichen zu knapp, um Zweck und "
                + "Beispiel zu nennen"
            )
            XCTAssertTrue(
                text.contains("Mika+FileScope"),
                "\(schluessel) sollte die App beim Namen nennen"
            )
        }
    }

    /// Apples eigene Negativbeispiele aus der Ablehnungsmeldung: „App would like to
    /// access your Contacts", „App needs microphone access". Wer so formuliert,
    /// beschreibt den Zweck nicht, sondern nur den Zugriff.
    func test_5_1_1_keineBeschreibungFolgtDemNegativmuster() throws {
        let plist = try infoPlist
        let muster = ["would like to access", "needs access", "requires access", "wants access"]
        for schluessel in Self.zweckbeschreibungen {
            guard let text = (plist[schluessel] as? String)?.lowercased() else { continue }
            for m in muster {
                XCTAssertFalse(
                    text.contains(m),
                    "\(schluessel) enthält \u{201E}\(m)\u{201C} — das ist Apples Negativbeispiel für "
                    + "eine Beschreibung, die den Zweck gerade nicht nennt"
                )
            }
        }
    }

    // MARK: - 2.1(a) · Der Export muss schreiben dürfen

    /// Ohne dieses Entitlement öffnet die Powerbox den Speichern-Dialog überhaupt
    /// nicht: kein Blatt, keine Datei, keine Fehlermeldung. Am 2026-09-02 an
    /// derselben App gegengeprüft, einmal read-only und einmal read-write signiert.
    /// Für den Prüfer sah der Export deshalb aus, als täte er nichts.
    func test_2_1_storeErlaubtSchreibenInGewaehlteDateien() throws {
        let ent = try storeEntitlements
        XCTAssertEqual(
            ent["com.apple.security.files.user-selected.read-write"] as? Bool, true,
            "Ohne user-selected.read-write öffnet die Powerbox den Speichern-Dialog "
            + "gar nicht erst — der Export bleibt wirkungslos, ohne jede Meldung."
        )
        XCTAssertNil(
            ent["com.apple.security.files.user-selected.read-only"],
            "read-only und read-write nebeneinander ist widersprüchlich; read-only "
            + "gehört entfernt."
        )
    }

    func test_2_1_storeVarianteBleibtSandboxed() throws {
        let ent = try storeEntitlements
        XCTAssertEqual(ent["com.apple.security.app-sandbox"] as? Bool, true,
                       "Der Store verlangt die Sandbox")
        XCTAssertEqual(ent["com.apple.security.files.bookmarks.app-scope"] as? Bool, true,
                       "Ohne app-scope-Bookmarks überlebt \u{201E}Rescan\u{201C} keinen Neustart")
    }

    // MARK: - Version

    /// Projektregel seit d940253: Kurzversion und Build-Nummer lauten gleich. Der
    /// Store weist einen erneuten Upload mit unveränderter Build-Nummer ab, deshalb
    /// muss sie bei jeder Wiedereinreichung mitwandern.
    func test_versionsnummernBleibenGleich() throws {
        let plist = try infoPlist
        let kurz = try XCTUnwrap(plist["CFBundleShortVersionString"] as? String)
        let build = try XCTUnwrap(plist["CFBundleVersion"] as? String)
        XCTAssertEqual(kurz, build,
                       "Projektregel: Kurzversion und Build-Nummer lauten gleich")
    }
}
