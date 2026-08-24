# B05 · Zeitachse — Systemdesign

Status: `review` · Stand: 2026-08-24 · geprüft, siehe `qa-report.md`

**Kein Code in diesem Dokument.**

## Überblick

Die Zeitachse entsteht in zwei Teilen an zwei Orten. Die Einordnung geschieht **während
des Scans** in `ScanEngine.dateBucketKey(for:)`: Jede Datei wird beim Durchlauf einem von
sieben Fenstern zugeschlagen, Anzahl und Volumen werden aufsummiert. Übrig bleiben sieben
Zahlenpaare — die einzelnen Daten sind dann verloren.

`HistogramView` zeichnet daraus zwei Balkendiagramme. Sie ist eine reine
Darstellungskomponente ohne eigene Logik außer der Farbberechnung.

Diese frühe Verdichtung ist der Grund, warum der Kategoriefilter hier nicht greifen
kann: Zum Zeitpunkt der Filterung existiert die Zuordnung Datei → Endung → Zeitfenster
nicht mehr.

## Komponentenstruktur

```
ScanEngine.performScan                       während des Scans
└── dateBucketKey(for: modDate)              → (key, sortIndex)
    └── dateBucketDict[key] += (count, bytes)
        └── [DateBucket] sortiert nach sortIndex

ContentView → Tab .timeline
└── HistogramView(dateBuckets: engine.dateBuckets)     ← ungefiltert
    └── ScrollView
        ├── "File Age Distribution"                    .headline
        ├── [leer] "No date information available"
        └── [gefüllt]
            ├── fileCountChart      BarMark(x: label, y: fileCount)     Höhe 220
            ├── Divider
            └── sizeChart           BarMark(x: label, y: totalBytes)    Höhe 220
                                    Achse über ByteCountFormatter
```

## Datenmodell

`DateBucket` — `Identifiable, Sendable`, definiert in `ScanEngine.swift`

| Feld | Typ | Bedeutung |
|---|---|---|
| `id` | String | zugleich Fensterschlüssel |
| `label` | String | identisch mit `id` |
| `fileCount` | Int | Dateien im Fenster |
| `totalBytes` | Int64 | Volumen im Fenster |
| `sortIndex` | Int | 0–6, erzwingt Reihenfolge und steuert die Farbe |

### Die sieben Fenster

| sortIndex | Schlüssel | Bedingung | dokumentiert |
|---|---|---|---|
| 0 | `Future` | Datum in der Zukunft | **nein** (FB-B05-02) |
| 1 | `Today` | 0 Tage | ja |
| 2 | `Past Week` | 1–7 Tage | ja |
| 3 | `Past Month` | 8–30 Tage | ja |
| 4 | `Past 3 Months` | 31–90 Tage | ja |
| 5 | `Past Year` | 91–365 Tage | ja |
| 6 | `Older` | älter | ja |

Nur Fenster, in denen mindestens eine Datei liegt, werden erzeugt (FB-B05-04).

## Farbberechnung

```
progress   = sortIndex / 6
saturation = 0.70 × (1 − progress × 0.6)
brightness = 0.75 × (1 − progress × 0.3)
hue        = 148/360   (fest)
```

Jüngere Fenster erscheinen kräftig, ältere entsättigt und dunkler. Der Ansatz ist
schlüssig; die drei Zahlen stehen allerdings ein zweites Mal im Code — dieselben Werte
wie in `Color.MikaPlus.chartPalette` (FB-B05-05, DS-03).

## Zugriffsregeln

Keine — reine Anzeige.

## Missbrauchsschutz

Nicht anwendbar. Die Verdichtung geschieht während des Scans; das Zeichnen kostet
nichts, weil höchstens sieben Balken je Diagramm entstehen.

## Erkennbare Entscheidungen

| # | Entscheidung | Alternative | Warum so |
|---|---|---|---|
| 1 | Verdichtung während des Scans | Änderungsdaten je Datei behalten | Konstanter Speicher statt linearem Wachstum. Preis: keine nachträgliche Filterung (FB-B05-01) |
| 2 | `sortIndex` als eigenes Feld | nach Datum sortieren | Die Fenster sind Zeichenketten; ohne Index gäbe es keine verlässliche Reihenfolge |
| 3 | Farbe aus dem `sortIndex` ableiten | feste Farbliste | Der Verlauf entsteht rechnerisch und passt sich an, wenn Fenster hinzukämen |
| 4 | `HistogramView` ohne eigene Logik | Verdichtung in der View | Richtig getrennt — die View bekommt fertige Werte |
| 5 | Fenster `Future` vorgesehen | negative Abstände auf `Today` abbilden | Grund nicht erkennbar; technisch sauber, aber nirgends beschrieben (FB-B05-02) |

## Abdeckung der Akzeptanzkriterien

| AK | Erfüllt durch |
|---|---|
| AK-01, AK-02 | `HistogramView` — Überschriften und zwei Diagrammabschnitte |
| AK-03 | `ScanEngine.dateBucketKey(for:)` |
| AK-04 | `sorted { $0.sortIndex < $1.sortIndex }` |
| AK-05 | `gradientColor(for:)` |
| AK-06 | `chartYAxis` mit `ByteCountFormatter` |
| AK-07 | `dateBuckets.isEmpty` → Hinweistext |
| AK-08 | `if let modDate = resourceValues.contentModificationDate` in `performScan` |
| AK-09 | Übergabe von `engine.dateBuckets` — **bestätigte Ausnahme**, siehe `spec.md` |


**AK-10, AK-11, AK-12 sind entfallen.** Sie wurden am 2026-08-23 als Fehler eingestuft
und in den *Fehlbestand* der Spec überführt; ihre Nummern bleiben unbesetzt. Was sie
beschrieben, wird von keiner Komponente erfüllt — es ist der Defekt selbst.

**Vollständig zugeordnet.** `DateBucket.label` ist mit `id` wortgleich und damit
genau genommen überflüssig — kein Fehler, aber ein Feld ohne eigenen Zweck.
