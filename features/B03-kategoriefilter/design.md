# B03 · Kategoriefilter — Systemdesign

Status: `review` · Stand: 2026-08-24 · geprüft, siehe `qa-report.md`

**Kein Code in diesem Dokument.**

## Überblick

Der Filter besteht aus drei Teilen: dem `FileCategory`-Aufzählungstyp mit den
Endungsmengen, drei berechneten Eigenschaften in `ScanEngine`, die ihn anwenden, und
einer Chip-Leiste in `ContentView`, die ihn setzt.

Der Aufbau ist richtig gedacht — eine einzige Stelle filtert, alle Ansichten lesen von
dort. Der Fehler liegt darin, dass drei der fünf Verbraucher die gefilterten
Eigenschaften **nicht** benutzen, sondern die rohen.

## Komponentenstruktur

```
ContentView
├── categoryBar                        ScrollView(.horizontal)
│   └── ForEach(FileCategory.allCases)
│       └── Button → engine.selectedCategory = category
│           Label(name, systemImage: icon) in Capsule
├── summaryBar        → filteredTotalFiles · filteredTotalSize · filteredGroups.count
├── listTab           → filteredGroups
├── ChartView         → filteredGroups, filteredTotalSize
├── HistogramView     → dateBuckets            ← ungefiltert (AK-11)
├── DuplicateDetector → scannedURLs            ← ungefiltert (AK-12)
└── noMatchState      wenn filteredGroups leer

ScanEngine
├── selectedCategory: FileCategory = .all
├── filteredGroups      → groups.filter { selectedCategory.matches(ext:) }
├── filteredTotalFiles  → Summe der count
└── filteredTotalSize   → Summe der totalBytes

MenubarPopoverView     → totalFiles · totalSize · groups   ← ungefiltert (AK-13)
```

## Wer folgt dem Filter — und wer nicht

| Verbraucher | Liest | Folgt |
|---|---|---|
| Kennzahlenleiste | `filteredTotalFiles`, `filteredTotalSize`, `filteredGroups` | ✓ |
| Tabelle (B02) | `filteredGroups` | ✓ |
| Diagramme (B04) | `filteredGroups`, `filteredTotalSize` | ✓ |
| Export (B07) | `filteredGroups`, `filteredTotal*` | ✓ |
| **Zeitachse (B05)** | `dateBuckets` | **✗** |
| **Duplikatsuche (B06)** | `scannedURLs` | **✗** |
| **Menüleiste (B08)** | `totalFiles`, `totalSize`, `groups` | **✗** |

Bei B05 wäre die Ursache tiefer: `dateBuckets` werden schon beim Scan verdichtet, ohne
dass die Endung mitgeführt wird — eine nachträgliche Filterung ist mit dem heutigen
Datenmodell gar nicht möglich. Bei B06 und B08 genügte es, die anderen Felder zu lesen.

## Datenmodell

`FileCategory` — `enum: String, CaseIterable, Identifiable, Sendable`

| Fall | Symbol | Endungen |
|---|---|---|
| `all` | `square.grid.2x2` | `nil` → trifft immer zu |
| `images` | `photo` | 17 |
| `documents` | `doc.text` | 18 |
| `videos` | `film` | 12 |
| `audio` | `music.note` | 12 |
| `code` | `chevron.left.forwardslash.chevron.right` | 33 |
| `archives` | `archivebox` | 14 |
| `other` | `questionmark.folder` | `nil` → Sonderfall |

Vollständige Listen in `docs/datenmodell.md`. Summe der benannten Endungen: 106, davon
`ts` doppelt vergeben.

`matches(ext:)` unterscheidet drei Fälle: `all` → immer wahr; `other` → Vereinigung aller
Mengen bilden und Nichtenthaltensein prüfen; sonst → Enthaltensein in der eigenen Menge.

## Zugriffsregeln

Keine — der Filter ist eine reine Anzeigeoperation ohne Datenzugriff.

## Missbrauchsschutz

Nicht anwendbar: keine Eingabe, keine Kosten, keine externen Aufrufe. Der einzige
Aufwand ist die Neuberechnung in `other` (FB-B03-02).

## Erkennbare Entscheidungen

| # | Entscheidung | Alternative | Warum so |
|---|---|---|---|
| 1 | Filterung als berechnete Eigenschaft | gefilterte Kopie vorhalten | Immer stimmig, kein Zustand, der veralten kann. Preis: Neuberechnung bei jedem Zugriff |
| 2 | `matches(ext:)` auf dem Aufzählungstyp | Zuordnungstabelle im Engine | Hält Symbol, Name und Endungen beieinander |
| 3 | „Other" als Ausschluss statt eigener Liste | Restliste pflegen | Bleibt automatisch richtig, wenn Endungen ergänzt werden. Preis: teure Neuberechnung (FB-B03-02) |
| 4 | Filter auf Endungsgruppen, nicht auf Dateien | einzelne Dateien filtern | Die Gruppen liegen bereits vor; Dateien müssten erneut durchlaufen werden. Erklärt zugleich, warum B05 nicht folgen **kann** |

## Abdeckung der Akzeptanzkriterien

| AK | Erfüllt durch |
|---|---|
| AK-01 | `categoryBar`, `FileCategory.allCases`, `icon` |
| AK-02 | `tealPrimary.opacity(0.2)` bzw. `secondary.opacity(0.1)` in `Capsule()` |
| AK-03 | `listTab` liest `filteredGroups` |
| AK-04 | `summaryBar` liest die gefilterten Summen |
| AK-05 | `ChartView(groups: filteredGroups, totalSize: filteredTotalSize)` |
| AK-06 | `ExportManager` bekommt die gefilterte Menge |
| AK-07 | `guard selectedCategory != .all else { return groups }` |
| AK-08 | `matches(ext:)`, Fall `.other` |
| AK-09 | `noMatchState` |
| AK-10 | Endungen liegen aus B01 bereits kleingeschrieben vor |


**AK-11 bis AK-15 sind entfallen.** Sie wurden am 2026-08-23 als Fehler eingestuft
und in den *Fehlbestand* der Spec überführt; ihre Nummern bleiben unbesetzt. Was sie
beschrieben, wird von keiner Komponente erfüllt — es ist der Defekt selbst.

**Vollständig zugeordnet.** Toter Code besteht in diesem Feature nicht.
