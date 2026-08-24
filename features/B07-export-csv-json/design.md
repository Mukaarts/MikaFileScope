# B07 · Export CSV und JSON — Systemdesign

Status: `review` · Stand: 2026-08-24 · geprüft, siehe `qa-report.md`

**Kein Code in diesem Dokument.**

## Überblick

`ExportManager` ist ein `@MainActor enum` ohne Instanzen — reine Funktionen, kein
Zustand. Zwei öffentliche Einstiege (CSV, JSON) erzeugen jeweils eine Zeichenkette und
reichen sie an eine gemeinsame Speicherroutine weiter, die den Systemdialog zeigt und
schreibt.

Die Aufteilung ist sauber: Erzeugen und Speichern sind getrennt, was den erzeugenden
Teil vollständig testbar machen würde — es gibt nur keinen Test.

## Ablauf

```
Menü „Export"                          .disabled(filteredGroups.isEmpty)
├── „Export CSV"  → ExportManager.exportCSV(groups:totalSize:folderURL:)
└── „Export JSON" → ExportManager.exportJSON(groups:totalFiles:totalSize:folderURL:)
    ├── generateCSV / generateJSON     → String
    ├── defaultName = "FileScope_<Ordnername>.<endung>"   Rückfall: „scan"
    └── save(content:defaultName:allowedType:)
        ├── NSSavePanel · nameFieldStringValue · allowedContentTypes
        ├── runModal() ≠ .OK → still zurück
        ├── write(to:atomically:true, encoding:.utf8)
        └── Fehler → NSAlert „Export Failed"
```

**Übergeben wird immer die gefilterte Menge** — `engine.filteredGroups`,
`engine.filteredTotalFiles`, `engine.filteredTotalSize`.

## Ausgabeformate

### CSV

```
Extension,Count,Size (Bytes),Size (Human),Percentage
".PNG",1240,58720256,"58.7 MB",42.1%
"(no extension)",3,1024,"1 KB",0.0%
```

| Spalte | Quelle | In Anführungszeichen | Format |
|---|---|---|---|
| `Extension` | `displayExt` | ja, innere verdoppelt | `.PNG` bzw. `(no extension)` |
| `Count` | `count` | nein | ganze Zahl |
| `Size (Bytes)` | `totalBytes` | nein | ganze Zahl |
| `Size (Human)` | `formattedSize` | ja | **sprachabhängig** (`ByteCountFormatter`) |
| `Percentage` | `percentage(of:)` | nein | `%.1f` + `%`, **sprachunabhängig** |

Die letzten beiden Zeilen dieser Tabelle sind die Ursache von FB-B07-03.

**Zur Einschleusung von Formeln:** Sie ist praktisch ausgeschlossen, weil jeder
Endungswert über `displayExt` mit einem Punkt beginnt oder `(no extension)` lautet — die
für Tabellenprogramme gefährlichen Anfangszeichen `=`, `+`, `-`, `@` können nicht an den
Anfang geraten. Das ist eher Nebenwirkung des Anzeigeformats als Absicht, wirkt aber.

### JSON

| Feld | Typ | Inhalt |
|---|---|---|
| `scannedFolder` | String | **vollständiger Pfad**, sonst `""` |
| `scannedAt` | String | ISO 8601 — Zeitpunkt des **Exports** (AK-16) |
| `totalFiles` | Int | gefilterte Anzahl |
| `totalSizeBytes` | Int64 | gefilterte Summe |
| `groups[]` | Array | `extension` (roh, ohne Punkt), `count`, `sizeBytes`, `sizeHuman`, `percentage` |

Erzeugt über `JSONSerialization` mit `.prettyPrinted` und `.sortedKeys`. Schlägt das
fehl, wird `"{}"` geschrieben — ohne Meldung (FB-B07-01).

Beachtenswert: In der CSV steht die Endung als `.PNG`, im JSON als `png`. Zwei
Darstellungen desselben Werts in zwei Ausgaben desselben Features.

## Zugriffsregeln

| Zugriff | Art | Erzwungen durch |
|---|---|---|
| Zielpfad | schreibend, **einmalig** | `NSSavePanel` — der Nutzer wählt selbst |
| Überschreiben | Rückfrage | Systemdialog |
| Sonstiges Schreiben | findet nicht statt | Aufbau |

Dies ist die einzige Schreiboperation der gesamten Anwendung.

## Missbrauchsschutz

| Risiko | Schutz | Lücke |
|---|---|---|
| Ungewolltes Überschreiben | Systemdialog fragt | keine |
| Formeleinschleusung in CSV | `displayExt` stellt einen Punkt voran | wirkt, ist aber nicht als Schutz gemeint |
| Ungewollte Weitergabe des Benutzernamens | — | **keiner** (AK-19, DZ-04) |
| Kosten pro Aufruf | entfällt | — |

## Externe Dienste

Keine. Die Datei geht an einen lokalen Ort; es findet keine Übertragung statt.

## Erkennbare Entscheidungen

| # | Entscheidung | Alternative | Warum so |
|---|---|---|---|
| 1 | Erzeugen und Speichern getrennt | alles in einer Funktion | Macht den erzeugenden Teil rein und prüfbar — ungenutzt (FB-B07-07) |
| 2 | `@MainActor enum` statt Klasse | Instanz | Kein Zustand vorhanden, keine Instanz nötig |
| 3 | Lesbare **und** rohe Größe in beiden Formaten | nur eine | Menschen lesen `58.7 MB`, Skripte rechnen mit `58720256` |
| 4 | `JSONSerialization` mit `[String: Any]` | `Codable`-Strukturen | Grund nicht erkennbar; `Codable` wäre typsicher gewesen und ohne Rückfallwert ausgekommen |
| 5 | `.sortedKeys` | Reihenfolge wie angelegt | Erzeugt bei gleichem Ergebnis identische Dateien — gut für Vergleiche |

## Abdeckung der Akzeptanzkriterien

| AK | Erfüllt durch |
|---|---|
| AK-01 | `ContentView.swift:109-127` — `Menu` mit zwei Einträgen |
| AK-02 | `.disabled(engine.filteredGroups.isEmpty)` |
| AK-03 | `save(content:defaultName:allowedType:)` |
| AK-04 | `guard panel.runModal() == .OK` |
| AK-05 | Übergabe von `filteredGroups` / `filteredTotal*` |
| AK-06, AK-07 | `generateCSV` |
| AK-08 | `replacingOccurrences(of: "\"", with: "\"\"")` |
| AK-09 | `encoding: .utf8` |
| AK-10 bis AK-13 | `generateJSON`, `JSONSerialization`, `round(… * 10) / 10` |
| AK-14 | `NSAlert` im `catch` |
| AK-15 | `NSSavePanel` selbst |


**AK-16, AK-17, AK-18, AK-19 sind entfallen.** Sie wurden am 2026-08-23 als Fehler eingestuft
und in den *Fehlbestand* der Spec überführt; ihre Nummern bleiben unbesetzt. Was sie
beschrieben, wird von keiner Komponente erfüllt — es ist der Defekt selbst.

**Vollständig abgedeckt.** Kein Bestandteil dieses Features ist ohne zugeordnetes
Kriterium — B07 ist damit das einzige bisher erfasste Feature ohne toten Code.
