# B06 · Duplikatsuche — Systemdesign

Status: `review` · Stand: 2026-08-24 · geprüft, siehe `qa-report.md`

**Kein Code in diesem Dokument.**

## Überblick

`DuplicateDetector` ist ein zweiter `@Observable @MainActor`-Zustandshalter neben
`ScanEngine` — anders als dieser lebt er aber als `@State` in `ContentView` und nicht im
`AppDelegate`. Er bekommt die Dateiliste aus dem letzten Scan übergeben und schiebt die
Arbeit über `Task.detached` in den Hintergrund, nach demselben Muster wie B01.

Der Vergleich läuft in zwei Stufen. Die erste ist billig und schließt fast alles aus:
Dateien, deren Größe kein zweites Mal vorkommt, können keine Duplikate sein. Erst die
verbleibenden werden gelesen und gehasht — blockweise, damit auch sehr große Dateien
den Speicher nicht sprengen.

## Ablauf

```
Button "Find Duplicates"
├── detector.detect(urls: engine.scannedURLs)     ← ungefiltert (AK-17)
└── showDuplicates = true                          → .sheet

detect(urls:)                                      @MainActor
├── guard !urls.isEmpty
├── isDetecting = true · progress = 0 · Ergebnis leeren
└── Task → Task.detached → findDuplicates(urls:)   nonisolated
    ├── Stufe 1 — nach Größe gruppieren
    │   ├── Größe < 1024 Bytes → überspringen
    │   └── behalten, wo dieselbe Größe ≥ 2-mal vorkommt
    ├── Stufe 2 — SHA-256 je Kandidat
    │   └── sha256Hash(of:)  FileHandle, 1-MB-Blöcke, autoreleasepool
    └── Gruppen mit ≥ 2 gleichen Hashes
└── zurück auf @MainActor
    ├── nach wastedBytes absteigend sortieren
    ├── totalWastedBytes summieren
    └── isDetecting = false · progress = 1.0        ← erst hier
```

## Komponentenstruktur

```
ContentView
├── Button "Find Duplicates"       .disabled(scannedURLs.isEmpty || isScanning)
└── .sheet → DuplicateResultView(detector:)        600 breit · 400–700 hoch
    ├── header                     Titel · „n groups • x recoverable" · Button „Done"
    ├── [isDetecting]  progressSection             ProgressView(value: progress) ← immer 0
    ├── [leer]         noDuplicatesView            Häkchen · „No duplicate files found"
    └── [Treffer]      resultsList
        ├── Hinweistext            „FileScope does not delete files…"
        └── List → Section je Gruppe
            ├── header             „n copies" · Größe · „(x wasted)" in Warnfarbe
            └── Zeile je Fundstelle
                ├── Dateiname (monospace) · Ordnerpfad (gekürzt in der Mitte)
                └── Lupe → NSWorkspace.activateFileViewerSelecting
```

## Datenstrukturen

### `DuplicateGroup`

| Feld | Typ | Bedeutung |
|---|---|---|
| `id` | UUID | flüchtig |
| `hash` | String | SHA-256 als Hex, 64 Zeichen |
| `fileSize` | Int64 | Größe **einer** Kopie |
| `urls` | [URL] | alle Fundstellen, mindestens zwei |
| `wastedBytes` | berechnet | `fileSize × (urls.count − 1)` |

### Zustand des Detektors

| Feld | Gesetzt | Gelesen von |
|---|---|---|
| `duplicateGroups` | nach Abschluss | Liste, Kopfzeile |
| `isDetecting` | Start und Ende | Umschaltung der drei Ansichten |
| `progress` | **nur 0 und 1.0** | Fortschrittsleiste — daher FB-B06-01 |
| `totalWastedBytes` | nach Abschluss | Kopfzeile |

## Zugriffsregeln

| Zugriff | Art | Erzwungen durch |
|---|---|---|
| Dateiinhalte | **lesend**, über `FileHandle(forReadingFrom:)` | Rechte des angemeldeten Nutzers |
| Finder öffnen | `NSWorkspace.activateFileViewerSelecting` | — |
| Verändern oder Löschen | **findet nicht statt** | Aufbau: es existiert kein solcher Code-Pfad |

Dies ist das einzige Feature, das Inhalte liest. Was gelesen wird, verlässt den Prozess
nicht: Aus jedem 1-MB-Block wird der Hash fortgeschrieben, der Block danach verworfen.

## Missbrauchsschutz

| Risiko | Schutz | Lücke |
|---|---|---|
| Sehr lange Laufzeit | Größenstufe schließt die Masse aus | kein Abbruch (FB-B06-02), kein Teilvergleich (FB-B06-05) |
| Speicherverbrauch | Blockweises Lesen | die Hash-Tabelle selbst wächst mit der Kandidatenzahl |
| Nutzer löscht versehentlich zu viel | Die App löscht **nicht** | falsch ausgewiesener Gewinn bei Hardlinks (AK-18) kann zu falschen Entscheidungen führen |
| Kosten pro Aufruf | entfällt — rein lokal | — |

## Externe Dienste

Keine.

## Erkennbare Entscheidungen

| # | Entscheidung | Alternative | Warum so |
|---|---|---|---|
| 1 | Zweistufig Größe → Hash | alles hashen | Die Größenstufe ist praktisch kostenlos und schließt fast alles aus. Richtige Wahl |
| 2 | SHA-256 statt xxHash/MD5 | schnellerer Hash mit Nachvergleich | Kollisionssicherheit ohne Byte-Vergleich am Ende. Kostet Rechenzeit, spart eine Fehlerquelle |
| 3 | 1-MB-Blöcke mit `autoreleasepool` | ganze Datei lesen | Auch Dateien größer als der Arbeitsspeicher sind verarbeitbar |
| 4 | Eigener `@Observable`-Zustandshalter | in `ScanEngine` integrieren | Trennt die teure Operation vom Scanzustand. Preis: er sitzt als `@State` in der View und ist damit nicht von B08 erreichbar |
| 5 | Blatt statt eigener Tab | vierter Tab neben List/Charts/Timeline | Betont, dass es sich um eine gezielte Aktion handelt, nicht um eine Ansicht |
| 6 | `progress` eingeführt, aber nie gefüllt | ganz weglassen oder korrekt füllen | **Grund nicht erkennbar** — vermutlich als Vorbereitung angelegt und vergessen (FB-B06-01) |

## Abdeckung der Akzeptanzkriterien

| AK | Erfüllt durch |
|---|---|
| AK-01 | `ContentView.swift:130-136` — `detect` + `showDuplicates` |
| AK-02 | `.disabled(engine.scannedURLs.isEmpty \|\| engine.isScanning)` |
| AK-03 | `@Environment(\.dismiss)`, Zustand bleibt im Detektor |
| AK-04 | `findDuplicates` Stufe 1 und 2 |
| AK-05, AK-06 | Gruppierung nach Hash |
| AK-07 | `guard size64 >= 1024` |
| AK-08 | `sha256Hash(of:)`, `chunkSize = 1024 * 1024` |
| AK-09 | `sorted { $0.wastedBytes > $1.wastedBytes }` |
| AK-10 | `DuplicateGroup.wastedBytes` |
| AK-11 | `header` mit `formattedWasted` |
| AK-12 | `Section`-Kopfzeile, Warnfarbe aus `Color.MikaPlus.destructive` |
| AK-13 | `NSWorkspace.shared.activateFileViewerSelecting` |
| AK-14 | `noDuplicatesView` |
| AK-15 | Hinweistext in `resultsList` — **nicht** im Leerfall (FB-B06-06) |


**AK-16, AK-17, AK-18, AK-19, AK-20 sind entfallen.** Sie wurden am 2026-08-23 als Fehler eingestuft
und in den *Fehlbestand* der Spec überführt; ihre Nummern bleiben unbesetzt. Was sie
beschrieben, wird von keiner Komponente erfüllt — es ist der Defekt selbst.

**Ohne Zuordnung:** `DuplicateGroup.formattedSize` und `hash` werden zwar berechnet, der
Hash aber nirgends angezeigt — er dient allein der Gruppierung.
