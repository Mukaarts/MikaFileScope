# B08 · Menüleisten-Kurzfassung — Systemdesign

Status: `review` · Stand: 2026-08-24 · geprüft, siehe `qa-report.md`

**Kein Code in diesem Dokument.**

## Überblick

Eine zweite SwiftUI-Szene neben dem Hauptfenster, eingeblendet über `MenuBarExtra` mit
`isInserted`-Bindung an eine Benutzereinstellung. Sie zeigt denselben `ScanEngine` wie
das Hauptfenster — beide bekommen die Instanz aus dem `AppDelegate`, weshalb ein Scan
sofort in beiden sichtbar wird.

Der `AppDelegate` beantwortet zusätzlich die Frage des Systems, ob die App nach dem
Schließen des letzten Fensters enden soll: Ist die Menüleiste aktiv, verneint er.

## Komponentenstruktur

```
MikaFileScopeApp
└── MenuBarExtra("FileScope", systemImage: "doc.viewfinder", isInserted: $showMenubar)
    .menuBarExtraStyle(.window)
    └── MenubarPopoverView(engine: appDelegate.engine)      Breite 280
        ├── headerView          Symbol · „Mika+FileScope" · Spinner bei isScanning
        ├── Divider
        ├── [gescannt] scanSummary
        │   ├── Ordnername                   .help(vollständiger Pfad)
        │   ├── miniStat ×3                  totalFiles · totalSize · groups.count
        │   └── Top 5                        je Endung: Name · ProgressView · Größe
        ├── [ungescannt] noScanView          Symbol · „No folder scanned"
        ├── Divider
        └── footerView          „Rescan" (bedingt) · „Quit" → NSApp.terminate

AppDelegate
├── engine: ScanEngine                       geteilt mit ContentView
├── sparkleUpdater: SparkleUpdater           gehört zu B09
└── applicationShouldTerminateAfterLastWindowClosed
    → !UserDefaults.standard.bool(forKey: "showMenubar")
```

## Zustand

| Wert | Speicher | Gelesen von |
|---|---|---|
| `showMenubar` | `UserDefaults` | `MikaFileScopeApp` (`@AppStorage`), `ContentView` (`@AppStorage`), `AppDelegate` (direkt) |
| Scanergebnis | `ScanEngine`, geteilt | Hauptfenster und Kurzfassung |

`showMenubar` ist der **einzige persistierte Wert der gesamten Anwendung** (siehe
`docs/datenmodell.md`) — und wird auf drei Wegen gelesen (FB-B08-03).

## Was gelesen wird — und was nicht

| Anzeige | Liest | Gefiltert |
|---|---|---|
| Files | `engine.totalFiles` | **nein** |
| Total | `engine.totalSize` | **nein** |
| Types | `engine.groups.count` | **nein** |
| Top 5 | `engine.groups`, sortiert nach `totalBytes` | **nein** |
| Anteilsbalken | `percentage(of: engine.totalSize)` | **nein** |

Die gefilterten Entsprechungen liegen unmittelbar daneben im selben Objekt bereit; sie
werden nicht benutzt (FB-B08-01). Anders als bei B05 wäre die Umstellung hier trivial.

## Zugriffsregeln

Keine eigenen. Die Kurzfassung löst über „Rescan" denselben Weg aus wie B01 und erbt
dessen Zugriffslage.

## Missbrauchsschutz

Nicht anwendbar. Ein Sonderfall verdient dennoch Erwähnung: „Quit" beendet die App
sofort über `NSApp.terminate(nil)`, **ohne Rückfrage** — auch während eines laufenden
Scans oder einer laufenden Duplikatsuche. Da nichts persistiert wird, geht dabei das
gesamte Ergebnis verloren.

## Erkennbare Entscheidungen

| # | Entscheidung | Alternative | Warum so |
|---|---|---|---|
| 1 | Zweite Szene statt zweites Fenster | `NSPanel` | `MenuBarExtra` ist die SwiftUI-eigene Form; ein- und ausblendbar über eine Bindung |
| 2 | `.window`-Darstellung | `.menu` | Balken und mehrspaltige Kennzahlen sind in einem Menü nicht darstellbar |
| 3 | Engine im `AppDelegate` | zwei getrennte Instanzen | Eine Wahrheit für beide Ansichten — der Grund, warum AK-12 ohne Zutun funktioniert |
| 4 | Top 5 statt Top 8 | dieselbe Zahl wie in den Diagrammen | 280 Punkt Breite lassen nicht mehr zu |
| 5 | Ungefilterte Werte | gefilterte | **Grund nicht erkennbar.** Vermutlich entstand die Ansicht vor dem Filter (Commit-Reihenfolge: Filter `6c0a202`, Menüleiste `f24b4b1` — also **nach** dem Filter, was gegen ein Versehen der Reihenfolge spricht) |

## Abdeckung der Akzeptanzkriterien

| AK | Erfüllt durch |
|---|---|
| AK-01 | `MenuBarExtra(…, isInserted: $showMenubar)` |
| AK-02 | `@AppStorage("showMenubar")` |
| AK-03, AK-04 | `applicationShouldTerminateAfterLastWindowClosed` |
| AK-05 | `.frame(width: 280)`, drei Bereiche mit Trennlinien |
| AK-06 | `scanSummary`, `prefix(5)` |
| AK-07 | `noScanView` |
| AK-08 | `ProgressView` im `headerView` bei `isScanning` |
| AK-09 | `footerView` → `engine.rescan()` |
| AK-10 | `.disabled(scannedFolderURL == nil \|\| isScanning)` |
| AK-11 | `NSApp.terminate(nil)` |
| AK-12 | geteilte `ScanEngine`-Instanz aus dem `AppDelegate` |


**AK-13 bis AK-16 sind entfallen.** Sie wurden am 2026-08-23 als Fehler eingestuft
und in den *Fehlbestand* der Spec überführt; ihre Nummern bleiben unbesetzt. Was sie
beschrieben, wird von keiner Komponente erfüllt — es ist der Defekt selbst.

**Vollständig zugeordnet.** Toter Code besteht in diesem Feature nicht.
