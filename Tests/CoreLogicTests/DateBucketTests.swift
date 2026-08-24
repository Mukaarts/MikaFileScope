// DateBucketTests.swift
// Prüft die Einordnung nach Alter (Feature B05, AK-03).
// Der Bezugszeitpunkt wird übergeben, damit die Prüfung unabhängig vom Kalendertag ist.

import XCTest
@testable import MikaFileScope

final class DateBucketTests: XCTestCase {

    private let jetzt = Date(timeIntervalSince1970: 1_800_000_000)  // fester Bezugspunkt
    private var kalender: Calendar { Calendar(identifier: .gregorian) }

    /// Datum über den Kalender bilden, nicht über 86.400 Sekunden: Zwischen zwei
    /// Kalendertagen kann eine Zeitumstellung liegen, und `dateBucketKey` rechnet in
    /// Kalendertagen.
    private func datum(vorTagen tage: Int) -> Date {
        kalender.date(byAdding: .day, value: -tage, to: jetzt)!
    }

    private func fenster(vorTagen tage: Int) -> String {
        ScanEngine.dateBucketKey(for: datum(vorTagen: tage), now: jetzt, calendar: kalender).key
    }

    // MARK: - AK-03 · Die Fenstergrenzen

    func test_AK03_fenstergrenzen() {
        XCTAssertEqual(fenster(vorTagen: 0), "Today")
        XCTAssertEqual(fenster(vorTagen: 1), "Past Week")
        XCTAssertEqual(fenster(vorTagen: 7), "Past Week")
        XCTAssertEqual(fenster(vorTagen: 8), "Past Month")
        XCTAssertEqual(fenster(vorTagen: 30), "Past Month")
        XCTAssertEqual(fenster(vorTagen: 31), "Past 3 Months")
        XCTAssertEqual(fenster(vorTagen: 90), "Past 3 Months")
        XCTAssertEqual(fenster(vorTagen: 91), "Past Year")
        XCTAssertEqual(fenster(vorTagen: 365), "Past Year")
        XCTAssertEqual(fenster(vorTagen: 366), "Older")
        XCTAssertEqual(fenster(vorTagen: 5000), "Older")
    }

    /// Ein Änderungsdatum in der Zukunft — etwa nach einer fehlerhaften Uhr — landet in
    /// einem eigenen Fenster. Es war lange undokumentiert (FB-B05-02).
    func test_zukunftsdatum() {
        let morgen = kalender.date(byAdding: .day, value: 1, to: jetzt)!
        XCTAssertEqual(ScanEngine.dateBucketKey(for: morgen, now: jetzt, calendar: kalender).key, "Future")
    }

    /// AK-04 · Die Reihenfolge muss chronologisch sein.
    func test_AK04_sortIndexIstChronologisch() {
        let reihenfolge = ["Future", "Today", "Past Week", "Past Month", "Past 3 Months", "Past Year", "Older"]
        var letzterIndex = -1
        for name in reihenfolge {
            let tage: Int
            switch name {
            case "Future": tage = -1
            case "Today": tage = 0
            case "Past Week": tage = 3
            case "Past Month": tage = 20
            case "Past 3 Months": tage = 60
            case "Past Year": tage = 200
            default: tage = 500
            }
            let index = ScanEngine.dateBucketKey(for: datum(vorTagen: tage), now: jetzt, calendar: kalender).sortIndex
            XCTAssertGreaterThan(index, letzterIndex, "\(name) muss nach dem vorigen Fenster kommen")
            letzterIndex = index
        }
    }
}
