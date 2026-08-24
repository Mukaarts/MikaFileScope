// StoreAssetTests.swift
// Prüft das Paket unter AppStore/ gegen die Vorgaben von App Store Connect.
//
// Ein eigener Prüfschritt statt eines Skripts: Die Limits sind der häufigste Grund
// für eine abgewiesene Einreichung, und `swift test` läuft ohnehin in der CI. Wer
// einen Text verlängert, merkt es hier — nicht erst im Formular.
//
// Alle Prüfungen laufen ohne Netzwerk und ohne laufende App.

import XCTest
import AppKit

final class StoreAssetTests: XCTestCase {

    // Projektwurzel aus dem Pfad dieser Datei ableiten — unabhängig vom Arbeitsverzeichnis.
    private var projectRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()   // StoreAssetTests
            .deletingLastPathComponent()   // Tests
            .deletingLastPathComponent()   // Projektwurzel
    }

    private var appStore: URL { projectRoot.appendingPathComponent("AppStore") }

    /// Feld → Höchstzahl Zeichen. Apple zählt Zeichen, nicht Bytes.
    private let limits: [String: Int] = [
        "name.txt": 30,
        "subtitle.txt": 30,
        "promotional_text.txt": 170,
        "description.txt": 4000,
        "keywords.txt": 100,
        "release_notes.txt": 4000,
    ]

    /// Lokalisierungen, die in App Store Connect angelegt sind.
    private let locales = ["en-US"]

    private let screenshotFormat = "mac-2880x1800"
    private let screenshotSize = NSSize(width: 2880, height: 1800)

    private func text(_ locale: String, _ feld: String) throws -> String {
        let url = appStore.appendingPathComponent("metadata/\(locale)/\(feld)")
        return try String(contentsOf: url, encoding: .utf8)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Metadaten

    func test_metadatenBleibenInDenZeichenlimits() throws {
        for locale in locales {
            for (feld, limit) in limits.sorted(by: { $0.key < $1.key }) {
                let inhalt = try text(locale, feld)
                XCTAssertFalse(inhalt.isEmpty, "\(locale)/\(feld) ist leer")
                XCTAssertLessThanOrEqual(
                    inhalt.count, limit,
                    "\(locale)/\(feld): \(inhalt.count) Zeichen, erlaubt sind \(limit)"
                )
            }
        }
    }

    func test_keywordsVerschenkenKeineZeichen() throws {
        for locale in locales {
            let keywords = try text(locale, "keywords.txt")
            // Ein Leerzeichen nach dem Komma zählt gegen das 100-Zeichen-Budget,
            // ohne die Suche zu verbessern.
            XCTAssertFalse(keywords.contains(", "),
                           "\(locale)/keywords.txt: Leerzeichen nach Komma verschenkt Budget")
            XCTAssertFalse(keywords.contains(",,"), "\(locale)/keywords.txt: leeres Schlüsselwort")
        }
    }

    func test_urlsSindGesetztUndAbsolut() throws {
        for locale in locales {
            for feld in ["support_url.txt", "marketing_url.txt", "privacy_url.txt"] {
                let url = try text(locale, feld)
                XCTAssertTrue(url.hasPrefix("https://"),
                              "\(locale)/\(feld): \(url) ist keine https-Adresse")
            }
        }
    }

    // MARK: - Screenshots

    func test_screenshotsHabenDieZugesagteGroesse() throws {
        for locale in locales {
            let ordner = appStore.appendingPathComponent("screenshots/\(locale)/\(screenshotFormat)")
            let dateien = try FileManager.default
                .contentsOfDirectory(at: ordner, includingPropertiesForKeys: nil)
                .filter { $0.pathExtension == "jpg" }
                .sorted { $0.lastPathComponent < $1.lastPathComponent }

            XCTAssertFalse(dateien.isEmpty, "\(locale): keine Screenshots")

            for datei in dateien {
                guard let rep = NSImageRep(contentsOf: datei) else {
                    XCTFail("\(datei.lastPathComponent) ließ sich nicht lesen")
                    continue
                }
                XCTAssertEqual(
                    NSSize(width: rep.pixelsWide, height: rep.pixelsHigh), screenshotSize,
                    "\(datei.lastPathComponent): \(rep.pixelsWide)×\(rep.pixelsHigh)"
                )
                // ASC weist Bilder mit Alphakanal zurück.
                XCTAssertFalse(rep.hasAlpha, "\(datei.lastPathComponent) hat einen Alphakanal")
            }
        }
    }

    func test_jedesMotivHatRohaufnahmeUndText() throws {
        struct Karte: Decodable { let rect: [CGFloat] }
        struct Motiv: Decodable { let file: String; let theme: String; let layout: String; let card: Karte? }
        struct Text: Decodable { let headline: String; let subline: String }
        struct Konfiguration: Decodable { let shots: [Motiv]; let texts: [String: [String: Text]] }

        let daten = try Data(contentsOf: appStore.appendingPathComponent("tools/shots.json"))
        let k = try JSONDecoder().decode(Konfiguration.self, from: daten)

        XCTAssertFalse(k.shots.isEmpty, "shots.json nennt kein Motiv")
        let bekannteLayouts: Set = ["hero", "text-top", "frame-top", "highlight"]
        let bekannteThemes: Set = ["light", "dark"]

        for motiv in k.shots {
            XCTAssertTrue(bekannteLayouts.contains(motiv.layout),
                          "\(motiv.file): compose.swift kennt kein Layout '\(motiv.layout)'")
            XCTAssertTrue(bekannteThemes.contains(motiv.theme),
                          "\(motiv.file): unbekanntes Thema '\(motiv.theme)'")
            if motiv.layout == "highlight" {
                XCTAssertNotNil(motiv.card, "\(motiv.file): Layout highlight ohne 'card'")
                XCTAssertEqual(motiv.card?.rect.count, 4,
                               "\(motiv.file): 'rect' braucht vier Werte")
            }
            // Eine fehlende Rohaufnahme darf nicht still auf eine andere Sprache
            // zurückfallen — das brächte englische Bilder in einen übersetzten Store.
            for (sprache, texte) in k.texts {
                let quelle = appStore
                    .appendingPathComponent("screenshots/raw/\(sprache)/\(motiv.file).png")
                XCTAssertTrue(FileManager.default.fileExists(atPath: quelle.path),
                              "Rohaufnahme fehlt: \(sprache)/\(motiv.file).png")
                XCTAssertNotNil(texte[motiv.file],
                                "shots.json: kein Text für \(motiv.file) in \(sprache)")
            }
        }
    }

    // MARK: - Inhaltliche Fallstricke

    func test_texteEnthaltenKeinePlatzhalter() throws {
        let verdaechtig = ["TODO", "TBD", "XXX", "Lorem ipsum", "PLACEHOLDER"]
        for locale in locales {
            let ordner = appStore.appendingPathComponent("metadata/\(locale)")
            for datei in try FileManager.default.contentsOfDirectory(at: ordner,
                                                                     includingPropertiesForKeys: nil)
            where datei.pathExtension == "txt" {
                let inhalt = try String(contentsOf: datei, encoding: .utf8)
                for marker in verdaechtig {
                    XCTAssertFalse(inhalt.localizedCaseInsensitiveContains(marker),
                                   "\(locale)/\(datei.lastPathComponent) enthält '\(marker)'")
                }
            }
        }
    }

    /// Die Altersfreigabe steht auf „kein Netzwerkzugriff“. Wer eine URLSession
    /// einbaut, macht damit stillschweigend den Fragebogen falsch — und den
    /// Datenschutz-Eintrag gleich mit.
    func test_keinNetzwerkzugriffImQuelltext() throws {
        let quellen = projectRoot.appendingPathComponent("Sources")
        let dateien = try FileManager.default
            .contentsOfDirectory(at: quellen, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "swift" }

        for datei in dateien {
            let inhalt = try String(contentsOf: datei, encoding: .utf8)
            for verboten in ["URLSession", "WKWebView", "NSURLConnection"] {
                XCTAssertFalse(
                    inhalt.contains(verboten),
                    """
                    \(datei.lastPathComponent) nennt \(verboten).                     AppStore/ALTERSFREIGABEN.md und der Datenschutz-Eintrag sagen                     beide, dass die App keine Verbindungen herstellt — beides prüfen.
                    """
                )
            }
        }
    }

    func test_altersfreigabeIstUeberallDieselbe() throws {
        let freigaben = try String(
            contentsOf: appStore.appendingPathComponent("ALTERSFREIGABEN.md"), encoding: .utf8)
        let grunddaten = try String(
            contentsOf: appStore.appendingPathComponent("APP_STORE_CONNECT.md"), encoding: .utf8)

        XCTAssertTrue(freigaben.contains("**Ergebnis: 4+**"),
                      "ALTERSFREIGABEN.md nennt kein Ergebnis")
        XCTAssertTrue(grunddaten.contains("4+"),
                      "APP_STORE_CONNECT.md nennt keine Altersfreigabe")
        // Beide Dateien werden von Hand gepflegt; ein Widerspruch fiele sonst erst
        // im Formular auf.
        for stufe in ["9+", "13+", "16+", "18+"] {
            XCTAssertFalse(grunddaten.contains("Altersfreigabe | \(stufe)"),
                           "APP_STORE_CONNECT.md sagt \(stufe), ALTERSFREIGABEN.md sagt 4+")
        }
    }

    func test_beschreibungNenntKeineFalscheMindestversion() throws {
        // Die Beschreibung nennt macOS 14; steht in Package.swift etwas anderes,
        // widersprechen sich Store-Eintrag und Build.
        let paket = try String(contentsOf: projectRoot.appendingPathComponent("Package.swift"),
                               encoding: .utf8)
        let beschreibung = try text("en-US", "description.txt")
        if paket.contains(".macOS(.v14)") {
            XCTAssertTrue(beschreibung.contains("macOS 14"),
                          "Package.swift baut für macOS 14, die Beschreibung sagt etwas anderes")
        }
    }
}
