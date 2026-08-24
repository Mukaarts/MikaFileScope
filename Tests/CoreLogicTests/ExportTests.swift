// ExportTests.swift
// Prüft die Erzeugung von CSV und JSON (Feature B07).
// Der erzeugende Teil ist bewusst vom Speichern getrennt und damit vollständig prüfbar —
// bis zur QA vom 2026-08-24 ungenutzt (FB-B07-07).

import XCTest
@testable import MikaFileScope

@MainActor
final class ExportTests: XCTestCase {

    private let gruppen = [
        FileTypeGroup(ext: "png", count: 5, totalBytes: 9_600),
        FileTypeGroup(ext: "pdf", count: 2, totalBytes: 65_000),
        FileTypeGroup(ext: "", count: 1, totalBytes: 600),
    ]
    private var summe: Int64 { gruppen.reduce(0) { $0 + $1.totalBytes } }

    // MARK: - AK-06/AK-07 · CSV

    func test_AK06_kopfzeile() {
        let csv = ExportManager.generateCSV(groups: gruppen, totalSize: summe)
        XCTAssertTrue(csv.hasPrefix("Extension,Count,Size (Bytes),Size (Human),Percentage\n"))
    }

    func test_AK07_zeilenaufbau() {
        let csv = ExportManager.generateCSV(groups: gruppen, totalSize: summe)
        let zeilen = csv.split(separator: "\n").map(String.init)
        XCTAssertEqual(zeilen.count, 4, "Kopfzeile plus drei Gruppen")
        XCTAssertTrue(zeilen[1].hasPrefix("\".PNG\",5,9600,"), "Endung in Anzeigeform, Anzahl, Bytes")
        XCTAssertTrue(zeilen[1].hasSuffix("%"), "Anteil endet auf Prozentzeichen")
        XCTAssertTrue(zeilen[3].hasPrefix("\"(no extension)\","), "Dateien ohne Endung")
    }

    /// AK-08 · Ein Anführungszeichen in der Endung wird nach CSV-Regel verdoppelt.
    func test_AK08_anfuehrungszeichenWerdenVerdoppelt() {
        let heikel = [FileTypeGroup(ext: "a\"b", count: 1, totalBytes: 10)]
        let csv = ExportManager.generateCSV(groups: heikel, totalSize: 10)
        XCTAssertTrue(csv.contains("\".A\"\"B\""), "Inneres Anführungszeichen muss verdoppelt sein")
    }

    /// Kein Zellinhalt darf mit einem Zeichen beginnen, das Tabellenprogramme als Formel
    /// deuten. Die Anzeigeform stellt einen Punkt voran — hier festgehalten, damit es so bleibt.
    func test_keineFormelnInDerCSV(){
        let boesartig = [FileTypeGroup(ext: "=cmd|' /c calc'!A0", count: 1, totalBytes: 10)]
        let csv = ExportManager.generateCSV(groups: boesartig, totalSize: 10)
        for zeile in csv.split(separator: "\n").dropFirst() {
            let ersteZelle = zeile.split(separator: ",").first ?? ""
            let inhalt = ersteZelle.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
            XCTAssertFalse("=+-@".contains(inhalt.first ?? " "),
                           "Zelle beginnt mit einem Formelzeichen: \(inhalt)")
        }
    }

    // MARK: - AK-10 bis AK-13 · JSON

    func test_AK10_grundstruktur() throws {
        let json = try XCTUnwrap(ExportManager.generateJSON(
            groups: gruppen, totalFiles: 8, totalSize: summe,
            folderURL: URL(fileURLWithPath: "/tmp/x"), scannedAt: Date()))
        let obj = try XCTUnwrap(try JSONSerialization.jsonObject(with: Data(json.utf8)) as? [String: Any])
        for schluessel in ["scannedFolder", "scannedAt", "totalFiles", "totalSizeBytes", "groups"] {
            XCTAssertNotNil(obj[schluessel], "Feld \(schluessel) fehlt")
        }
        XCTAssertEqual(obj["totalFiles"] as? Int, 8)
    }

    /// BUG-09 · Der Anteil stand als `5.0999999999999996` in der Datei, weil
    /// `round(x * 10) / 10` den nächstliegenden Double liefert und JSONSerialization
    /// ihn in voller Genauigkeit ausschreibt.
    func test_BUG09_anteilHatEineNachkommastelle() throws {
        let json = try XCTUnwrap(ExportManager.generateJSON(
            groups: gruppen, totalFiles: 8, totalSize: summe, folderURL: nil, scannedAt: nil))
        for zeile in json.split(separator: "\n") where zeile.contains("\"percentage\"") {
            let wert = zeile.split(separator: ":").last?.trimmingCharacters(in: .whitespaces)
                .trimmingCharacters(in: CharacterSet(charactersIn: ",")) ?? ""
            let nachkomma = wert.split(separator: ".").last.map(String.init) ?? ""
            XCTAssertLessThanOrEqual(nachkomma.count, 1,
                                     "Anteil mit mehr als einer Nachkommastelle: \(wert)")
        }
    }

    func test_decimalPercentageRundetKaufmaennisch() {
        XCTAssertEqual(ExportManager.decimalPercentage(5.14).stringValue, "5.1")
        XCTAssertEqual(ExportManager.decimalPercentage(5.15).stringValue, "5.2")
        XCTAssertEqual(ExportManager.decimalPercentage(0).stringValue, "0")
    }

    /// FB-B07-04 · `scannedAt` nennt den Scanzeitpunkt, nicht den des Exports.
    func test_FB0704_scannedAtIstDerScanzeitpunkt() throws {
        let scan = Date(timeIntervalSince1970: 1_700_000_000)
        let json = try XCTUnwrap(ExportManager.generateJSON(
            groups: gruppen, totalFiles: 8, totalSize: summe, folderURL: nil, scannedAt: scan))
        let obj = try XCTUnwrap(try JSONSerialization.jsonObject(with: Data(json.utf8)) as? [String: Any])
        let text = try XCTUnwrap(obj["scannedAt"] as? String)
        let zurueck = try XCTUnwrap(ISO8601DateFormatter().date(from: text))
        XCTAssertEqual(zurueck.timeIntervalSince1970, scan.timeIntervalSince1970, accuracy: 1)
    }

    // MARK: - AK-10 in B02 · Division durch null

    func test_anteilBeiGesamtgroesseNull() {
        XCTAssertEqual(gruppen[0].percentage(of: 0), 0)
    }

    func test_displayExt() {
        XCTAssertEqual(FileTypeGroup(ext: "png", count: 1, totalBytes: 1).displayExt, ".PNG")
        XCTAssertEqual(FileTypeGroup(ext: "", count: 1, totalBytes: 1).displayExt, "(no extension)")
    }

    /// AK-10 in B06 · Verschwendeter Platz ist Größe × (Anzahl − 1).
    func test_verschwendeterPlatz() {
        let g = DuplicateGroup(hash: "x", fileSize: 5_000,
                               urls: [URL(fileURLWithPath: "/a"), URL(fileURLWithPath: "/b")])
        XCTAssertEqual(g.wastedBytes, 5_000)
        let g3 = DuplicateGroup(hash: "y", fileSize: 1_000,
                                urls: (0..<3).map { URL(fileURLWithPath: "/\($0)") })
        XCTAssertEqual(g3.wastedBytes, 2_000)
    }
}
