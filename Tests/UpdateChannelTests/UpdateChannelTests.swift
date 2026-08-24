// UpdateChannelTests.swift
// Prüft den Sparkle-Update-Kanal (Feature B09) gegen Resources/Info.plist und appcast.xml.
//
// Diese Tests entstanden in der QA vom 2026-08-23. Sie fangen genau die Defekte ab,
// die dort gefunden wurden: leerer Feed, eingefrorene Build-Nummer, Feed auf dem
// falschen Branch. Alle laufen ohne Netzwerk und ohne laufende App.

import XCTest

final class UpdateChannelTests: XCTestCase {

    // Projektwurzel aus dem Pfad dieser Datei ableiten — unabhängig vom Arbeitsverzeichnis.
    private var projectRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()   // UpdateChannelTests
            .deletingLastPathComponent()   // Tests
            .deletingLastPathComponent()   // Projektwurzel
    }

    private var infoPlist: [String: Any] {
        get throws {
            let url = projectRoot.appendingPathComponent("Resources/Info.plist")
            let data = try Data(contentsOf: url)
            guard let dict = try PropertyListSerialization
                .propertyList(from: data, format: nil) as? [String: Any] else {
                throw XCTSkip("Info.plist nicht lesbar")
            }
            return dict
        }
    }

    private var appcastXML: String {
        get throws {
            try String(contentsOf: projectRoot.appendingPathComponent("appcast.xml"), encoding: .utf8)
        }
    }

    // MARK: - AK-12 · Der Feed wird über HTTPS geladen

    func test_AK12_feedURLVerwendetHTTPS() throws {
        let feed = try XCTUnwrap(infoPlist["SUFeedURL"] as? String)
        XCTAssertTrue(feed.hasPrefix("https://"),
                      "SUFeedURL muss HTTPS verwenden, ist aber: \(feed)")
    }

    // MARK: - AK-07 · Signaturprüfung ist erzwungen

    func test_AK07_oeffentlicherSchluesselIstGesetzt() throws {
        let key = try XCTUnwrap(infoPlist["SUPublicEDKey"] as? String,
                                "Ohne SUPublicEDKey prüft Sparkle keine Signaturen")
        XCTAssertFalse(key.isEmpty)
        XCTAssertEqual(Data(base64Encoded: key)?.count, 32,
                       "Ein EdDSA-Schlüssel ist 32 Byte lang")
    }

    // MARK: - FB-B09-02 · Die Build-Nummer darf nicht einfrieren

    func test_FB0902_buildNummerPasstZurKurzversion() throws {
        let short = try XCTUnwrap(infoPlist["CFBundleShortVersionString"] as? String)
        let build = try XCTUnwrap(infoPlist["CFBundleVersion"] as? String)
        let buildNr = try XCTUnwrap(Int(build), "CFBundleVersion muss eine Zahl sein: \(build)")
        let major = try XCTUnwrap(Int(short.split(separator: ".").first.map(String.init) ?? ""),
                                  "Kurzversion unerwartet: \(short)")

        // Sparkle vergleicht CFBundleVersion. Steht sie auf 1, während die Kurzversion
        // bereits bei 2.x liegt, gilt jedes Update als "nicht neuer".
        XCTAssertGreaterThanOrEqual(
            buildNr, major,
            "CFBundleVersion (\(build)) ist kleiner als die Hauptversion von \(short). "
            + "Sparkle vergleicht die Build-Nummer — sie muss mit jedem Release steigen."
        )
    }

    // MARK: - FB-B09-11 · Der Feed muss auf dem gepflegten Zweig liegen

    /// Verglichen wird gegen den Hauptzweig des Projekts, nicht gegen den gerade
    /// ausgecheckten: Auf einem Feature-Zweig zu arbeiten ist normal und darf den
    /// Test nicht rot färben. `master` existiert im Repository noch, wird aber nicht
    /// gepflegt — ein Feed von dort erreicht niemanden mit aktuellen Ständen.
    func test_FB0911_feedZeigtAufDenGepflegtenZweig() throws {
        let feed = try XCTUnwrap(infoPlist["SUFeedURL"] as? String)
        XCTAssertTrue(feed.contains("/main/"),
                      "Der Feed muss auf den Hauptzweig `main` zeigen: \(feed)")
        XCTAssertFalse(feed.contains("/master/"),
                       "`master` wird nicht gepflegt und ist als Feed-Quelle untauglich")
    }

    // MARK: - FB-B09-03 · Die Feed-URL muss auf das aktuelle Konto zeigen

    func test_FB0903_feedNenntKeinVeraltetesKonto() throws {
        let feed = try XCTUnwrap(infoPlist["SUFeedURL"] as? String)
        XCTAssertFalse(feed.contains("Mukaarts"),
                       "Der Feed zeigt auf den früheren, inzwischen freigegebenen Kontonamen")
    }

    // MARK: - FB-B09-01 · Der Feed muss den ausgelieferten Stand kennen

    func test_FB0901_appcastEnthaeltEinenEintrag() throws {
        let xml = try appcastXML
        XCTAssertTrue(xml.contains("<item>"),
                      "appcast.xml enthält kein <item> — kein installierter Client erfährt je von einem Update")
    }

    func test_FB0901_appcastNenntDieAktuelleVersion() throws {
        let xml = try appcastXML
        let short = try XCTUnwrap(infoPlist["CFBundleShortVersionString"] as? String)
        XCTAssertTrue(xml.contains(short),
                      "appcast.xml erwähnt die ausgelieferte Version \(short) nicht")
    }

    func test_FB0901_jederEintragTraegtEineSignatur() throws {
        let xml = try appcastXML
        let items = xml.components(separatedBy: "<item>").dropFirst()
        for (i, item) in items.enumerated() {
            XCTAssertTrue(item.contains("sparkle:edSignature"),
                          "Eintrag \(i + 1) trägt keine EdDSA-Signatur und würde abgelehnt")
            XCTAssertTrue(item.contains("length="),
                          "Eintrag \(i + 1) nennt keine Dateilänge")
        }
    }
}
