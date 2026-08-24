# B02 · Aufschlüsselung nach Dateityp — Systemdesign

Status: `review` · Stand: 2026-08-24 · geprüft, siehe `qa-report.md`

**Kein Code in diesem Dokument.**

## Überblick

Eine SwiftUI-`Table` über `engine.filteredGroups` mit vier Spalten, darüber drei
Kennzahl-Pillen. Die Sortierung läuft über eine `KeyPathComparator`-Liste im
View-Zustand; bei Änderung wird nicht die Anzeige, sondern die Quelle in `ScanEngine`
umsortiert.

Die Farbzuordnung ist der interessante Teil: Sie richtet sich nach der Größenrangfolge,
nicht nach der Zeilenposition — eine Endung behält ihre Farbe, auch wenn der Nutzer nach
Anzahl sortiert. Umgesetzt ist das allerdings so, dass die Rangfolge für **jede Zeile
erneut** ermittelt wird.

## Komponentenstruktur

```
ContentView
├── summaryBar                              HStack, Abstand 16
│   ├── StatPill "Files"                    filteredTotalFiles
│   ├── StatPill "Total Size"               filteredTotalSize, ByteCountFormatter
│   └── StatPill "Types"                    filteredGroups.count
└── listTab
    └── Table(engine.filteredGroups, sortOrder: $sortOrder)
        ├── TableColumn "Extension"   value: \.ext         min 120, ideal 160
        │   └── Farbbalken 4×18, Radius 2 · displayExt in Festbreitenschrift
        ├── TableColumn "Count"       value: \.count       min 60, ideal 80
        ├── TableColumn "Size"        value: \.totalBytes  min 80, ideal 120
        └── TableColumn "% of Total"  ← kein value: (AK-12)
            └── ProgressView(value: pct, total: 100) · Text "%.1f%%"
        .onChange(of: sortOrder) → engine.groups.sort(using:)
```

`StatPill` ist ein `private struct` in derselben Datei: Wert in `.title3` mit fester
Ziffernbreite und Fettung, darunter die Beschriftung in `.caption`, das Ganze auf
`.secondary.opacity(0.1)` mit Radius 8.

## Datenfluss

```
ScanEngine.groups  ──filter──▶  filteredGroups  ──▶  Table
       ▲                                              │
       └──────────── sort(using:) ◀───────────────────┘
                     .onChange(of: sortOrder)
```

Der Rückkanal ist die Eigenheit dieses Entwurfs: Die Anzeige sortiert ihre eigene Quelle
um. Es funktioniert, weil `filteredGroups` die Reihenfolge von `groups` erbt — aber die
Tabelle verändert damit Zustand, der ihr nicht gehört (FB-B02-03).

## Farbzuordnung

| Schritt | Was geschieht |
|---|---|
| 1 | `filteredGroups` wird absteigend nach `totalBytes` sortiert |
| 2 | Der Index der aktuellen Gruppe wird darin gesucht |
| 3 | Liegt er unter 8 → Farbe aus `Color.MikaPlus.chartPalette`, sonst `.gray` |

Schritt 1 und 2 laufen **je Zeile** (FB-B02-01). Die Palette ist dieselbe wie in B04,
weshalb Tabelle und Diagramme dieselbe Endung gleich einfärben — mit der Einschränkung
aus `docs/design-system.md`, DS-01: Die erste Palettenfarbe ist nicht die Markenfarbe,
der Fortschrittsbalken daneben aber schon.

## Zugriffsregeln

Keine — reine Anzeige ohne Datenzugriff, ohne Schreiboperation.

## Missbrauchsschutz

Nicht anwendbar. Der einzige Aufwandsposten ist die Farbzuordnung (FB-B02-01).

## Erkennbare Entscheidungen

| # | Entscheidung | Alternative | Warum so |
|---|---|---|---|
| 1 | `Table` mit `sortOrder`-Bindung | eigene Sortierlogik | Nutzt die Plattformmechanik; Klick auf die Kopfzeile funktioniert ohne Zutun |
| 2 | Sortierung auf `engine.groups` anwenden | eine sortierte Kopie in der View halten | Grund nicht erkennbar. Vermutlich der kürzeste Weg, damit `filteredGroups` die Reihenfolge übernimmt |
| 3 | `ProgressView` als Anteilsbalken | eigenes Rechteck | Fertig, adaptiv, mit `tint` einfärbbar |
| 4 | Farbe nach Größenrang | nach Zeilenposition | Stabile Farbe je Endung — die fachlich richtige Wahl, technisch teuer umgesetzt |
| 5 | `StatPill` privat in `ContentView.swift` | eigene Datei, geteilt | Grund nicht erkennbar; führte dazu, dass B08 eine zweite Fassung baute (FB-B02-05) |

## Abdeckung der Akzeptanzkriterien

| AK | Erfüllt durch |
|---|---|
| AK-01 | `Table` mit vier `TableColumn` |
| AK-02 | `@State sortOrder` mit `\.count, order: .reverse` |
| AK-03 | `sortOrder`-Bindung + `.onChange` |
| AK-04 | `RoundedRectangle(cornerRadius: 2).frame(width: 4, height: 18)`, `displayExt` |
| AK-05 | `ProgressView(value:total:)` mit `tint`, `String(format: "%.1f%%")` |
| AK-06 | `group.percentage(of: engine.filteredTotalSize)` |
| AK-07 | `.monospacedDigit()` in allen Zahlenspalten |
| AK-08 | `summaryBar` mit drei `StatPill` |
| AK-09 | `FileTypeGroup.formattedSize` über `ByteCountFormatter` |
| AK-10 | `guard totalSize > 0 else { return 0 }` |


**AK-11, AK-12, AK-13, AK-14 sind entfallen.** Sie wurden am 2026-08-23 als Fehler eingestuft
und in den *Fehlbestand* der Spec überführt; ihre Nummern bleiben unbesetzt. Was sie
beschrieben, wird von keiner Komponente erfüllt — es ist der Defekt selbst.

**Vollständig zugeordnet.** Toter Code besteht in diesem Feature nicht.
