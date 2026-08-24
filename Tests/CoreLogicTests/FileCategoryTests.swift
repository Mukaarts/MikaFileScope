// FileCategoryTests.swift
// Prüft die Zuordnung von Endungen zu Kategorien (Feature B03).
// Reine Rechenlogik ohne Dateisystemzugriff — der am einfachsten prüfbare Teil der App
// und bis zur QA vom 2026-08-24 vollständig ungeprüft (BF-23).

import XCTest
@testable import MikaFileScope

final class FileCategoryTests: XCTestCase {

    // MARK: - AK-07 · „All" reicht alles durch

    func test_AK07_allTrifftImmerZu() {
        for ext in ["png", "swift", "", "völligUnbekannt", "ZIP"] {
            XCTAssertTrue(FileCategory.all.matches(ext: ext), "All muss \(ext) enthalten")
        }
    }

    // MARK: - Zuordnung je Kategorie

    func test_bekannteEndungenLandenInIhrerKategorie() {
        let faelle: [(FileCategory, String)] = [
            (.images, "png"), (.images, "heic"), (.images, "cr2"),
            (.documents, "pdf"), (.documents, "epub"),
            (.videos, "mp4"), (.videos, "mkv"),
            (.audio, "mp3"), (.audio, "flac"),
            (.code, "swift"), (.code, "rs"),
            (.archives, "zip"), (.archives, "dmg"),
        ]
        for (kategorie, ext) in faelle {
            XCTAssertTrue(kategorie.matches(ext: ext), "\(ext) gehört zu \(kategorie.rawValue)")
        }
    }

    func test_fremdeEndungLandetNichtInDerKategorie() {
        XCTAssertFalse(FileCategory.images.matches(ext: "mp4"))
        XCTAssertFalse(FileCategory.audio.matches(ext: "pdf"))
        XCTAssertFalse(FileCategory.code.matches(ext: "png"))
    }

    // MARK: - AK-08 · „Other" ist der Rest

    func test_AK08_otherEnthaeltNurUnbekannte() {
        XCTAssertTrue(FileCategory.other.matches(ext: "xyz"))
        XCTAssertTrue(FileCategory.other.matches(ext: ""), "Dateien ohne Endung gehören zu Other")
        XCTAssertFalse(FileCategory.other.matches(ext: "png"))
        XCTAssertFalse(FileCategory.other.matches(ext: "swift"))
    }

    /// Die Summe der Kategorien darf den Gesamtbestand nicht übersteigen: Jede Endung
    /// gehört zu genau einer benannten Kategorie. `ts` stand zuvor bei Videos **und**
    /// bei Code (FB-B03-03).
    func test_FB0303_keineEndungInZweiKategorien() {
        let benannte = FileCategory.allCases.filter { $0 != .all && $0 != .other }
        var gesehen: [String: FileCategory] = [:]
        for kategorie in benannte {
            for ext in kategorie.extensions ?? [] {
                if let vorher = gesehen[ext] {
                    XCTFail("`\(ext)` steht in \(vorher.rawValue) und in \(kategorie.rawValue)")
                }
                gesehen[ext] = kategorie
            }
        }
    }

    func test_grossKleinschreibungWirdVomScanNormalisiert() {
        // Der Scan legt Endungen kleingeschrieben ab; die Zuordnung erwartet das.
        XCTAssertTrue(FileCategory.images.matches(ext: "png"))
        XCTAssertFalse(FileCategory.images.matches(ext: "PNG"),
                       "Großschreibung kommt hier nie an — ScanEngine normalisiert vorher")
    }
}
