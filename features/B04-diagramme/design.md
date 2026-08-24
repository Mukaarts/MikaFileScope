# B04 · Diagramme — Systemdesign

Status: `review` · Stand: 2026-08-24 · geprüft, siehe `qa-report.md`

**Kein Code in diesem Dokument.**

## Überblick

`ChartView` bekommt die gefilterten Gruppen und die gefilterte Gesamtgröße und baut
daraus eine eigene Darstellungsliste: die acht größten Endungen einzeln, alles Weitere
als grauer Sammelposten. Aus dieser Liste entstehen zwei Diagramme mit Swift Charts —
ein `SectorMark`-Ring und ein `BarMark`-Balkendiagramm — sowie eine selbstgebaute
Legende.

Die Komponente ist zustandslos: Sie hält nichts, sondern rechnet bei jedem Zeichnen neu.
Genau darin liegt auch ihr einziger technischer Befund.

## Komponentenstruktur

```
ChartView(groups: filteredGroups, totalSize: filteredTotalSize)
├── chartData                                    berechnet — je Zugriff neu (FB-B04-01)
│   ├── sortiert absteigend nach totalBytes
│   ├── prefix(8)  → ChartItem mit Palettenfarbe
│   └── dropFirst(8) → ein ChartItem „Other", grau, Summen aufaddiert
└── ScrollView
    ├── donutSection
    │   ├── "Distribution by Size"               .headline
    │   ├── Chart → SectorMark                   260 × 260
    │   │   innerRadius .ratio(0.5) · angularInset 1.5 · cornerRadius 4
    │   └── legend                               min. 180 breit
    │       └── je Eintrag: Punkt 10 pt · Endung · Größe rechtsbündig
    ├── Divider
    └── barSection
        ├── "Top File Types by Size"             .headline
        └── Chart → BarMark(x: bytes, y: label)  Höhe = Anzahl × 36 + 20
            chartXAxis mit ByteCountFormatter
    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: groups.map(\.id))
```

## Datenmodell

`ChartItem` — `Identifiable`, definiert in `ChartView.swift`

| Feld | Typ | Herkunft | Verwendet |
|---|---|---|---|
| `id` | String | Endung, `"no-ext"` oder `"other"` | ForEach, Chart |
| `label` | String | `displayExt` bzw. `"Other"` | Legende, Balkenachse |
| `bytes` | Int64 | `totalBytes` bzw. Summe | beide Diagramme |
| `count` | Int | `count` bzw. Summe | **nirgends** (FB-B04-05) |
| `color` | Color | Palette oder `.gray` | beide Diagramme, Legende |

## Farbzuordnung

Index 0–7 aus `Color.MikaPlus.chartPalette`, alles darüber als ein grauer Sammelposten.
Dieselbe Palette und dieselbe Rangfolge nach Größe wie in B02 — eine Endung hat in
Tabelle und Diagramm dieselbe Farbe.

Zwei Einschränkungen aus `docs/design-system.md`:

- **DS-01** — `chartPalette[0]` ist `#39BF77`, nicht die Markenfarbe `#1D9E75`. Der Ring
  beginnt also mit einem Grün, das die Marke nicht führt.
- **DS-08** — Fester Sättigungs- und Helligkeitswert über alle acht Farbtöne lässt Gelb
  und Cyan stärker hervortreten als Blau und Violett.

## Zugriffsregeln

Keine — reine Anzeige.

## Missbrauchsschutz

Nicht anwendbar. Der einzige Aufwandsposten ist die dreifache Neuberechnung
(FB-B04-01), begrenzt auf höchstens neun Einträge.

## Erkennbare Entscheidungen

| # | Entscheidung | Alternative | Warum so |
|---|---|---|---|
| 1 | Eigene `ChartItem`-Liste | `FileTypeGroup` direkt zeichnen | „Other" ist keine echte Gruppe und braucht eine eigene Darstellung |
| 2 | Selbstgebaute Legende | `chartForegroundStyleScale` | Volle Kontrolle über Anordnung und Größenangabe; dafür keine automatische Verknüpfung mit dem Diagramm |
| 3 | Höhe des Balkendiagramms rechnerisch | feste Höhe | Balken behalten ihre Dicke, unabhängig von der Anzahl |
| 4 | Animation an `groups.map(\.id)` gebunden | an die Gruppen selbst | `FileTypeGroup` vergleicht über die `id`; die Abbildung auf IDs ist der zuverlässige Auslöser |
| 5 | Ring **und** Balken statt nur einem | eines von beiden | Der Ring zeigt Anteile, die Balken den Vergleich. Beide aus derselben Liste |

## Abdeckung der Akzeptanzkriterien

| AK | Erfüllt durch |
|---|---|
| AK-01 | `donutSection` und `barSection` |
| AK-02 | `sorted { $0.totalBytes > $1.totalBytes }` |
| AK-03 | `prefix(8)` / `dropFirst(8)` mit Summenbildung |
| AK-04 | `if !rest.isEmpty` |
| AK-05 | `SectorMark(innerRadius: .ratio(0.5), angularInset: 1.5)`, `cornerRadius(4)` |
| AK-06 | `legend` |
| AK-07 | `chartXAxis` mit `ByteCountFormatter` |
| AK-08 | `CGFloat(chartData.count) * 36 + 20` |
| AK-09 | `.animation(.spring(…))` |
| AK-10 | Übergabe von `filteredGroups` aus `ContentView` |


**AK-11 bis AK-14 sind entfallen.** Sie wurden am 2026-08-23 als Fehler eingestuft
und in den *Fehlbestand* der Spec überführt; ihre Nummern bleiben unbesetzt. Was sie
beschrieben, wird von keiner Komponente erfüllt — es ist der Defekt selbst.

**Ohne Zuordnung:** `ChartItem.count` und `ChartItem.formattedSize` — Ersteres wird
nirgends angezeigt (FB-B04-05), Letzteres nur in der Legende.
