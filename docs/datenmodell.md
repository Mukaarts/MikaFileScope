# Mika+FileScope — Datenmodell

Stand: 2026-08-23 · Stack-Profil: `swiftui-macos`
Rückwirkend erfasst aus `Sources/`. Beschrieben ist der Bestand, nicht ein Sollzustand.

## Die entscheidende Eigenschaft: es gibt keine Datenbank

Kein Postgres, kein SQLite, kein Core Data, kein CloudKit, keine Datei im Application
Support. Das gesamte Modell lebt **im Arbeitsspeicher einer einzigen Instanz** und ist
mit dem Beenden der App weg. Persistiert wird genau ein Wert, und der ist ein Schalter.

Das ist keine Lücke, sondern die tragende Entwurfsentscheidung: Es gibt nichts zu
migrieren, nichts zu löschen und nichts, das ein Update verlieren könnte. Alles, was in
einem Datenmodell sonst Aufmerksamkeit verlangt — Löschfristen, Fremdschlüssel,
Migrationspfade —, entfällt hier nachweislich und nicht bloß behauptet.

## Persistente Daten

| Speicher | Schlüssel | Typ | Vorgabe | Bedeutung |
|---|---|---|---|---|
| `UserDefaults` | `showMenubar` | Bool | `false` | Ob das Menüleistensymbol eingeblendet ist. Gelesen über `@AppStorage` in `MikaFileScopeApp` und `ContentView`, zusätzlich direkt über `UserDefaults.standard.bool(forKey:)` in `AppDelegate` |

Das ist die vollständige Liste. Weitere Zustände legt Sparkle selbst in der Domain der
App ab (letzter Prüfzeitpunkt, automatische Prüfung) — geschrieben von der Bibliothek,
nicht von diesem Code.

**Folge, die im Alltag auffällt:** Der zuletzt gescannte Ordner wird nicht gemerkt. Nach
einem Neustart steht die App wieder im Leerzustand, obwohl die Menüleisten-Kurzfassung
optisch nahelegt, sie hätte ein Gedächtnis.

## Strukturen im Arbeitsspeicher

### `FileTypeGroup` — eine Zeile der Aufschlüsselung

`Identifiable, Hashable, Sendable` · `Sources/FileTypeGroup.swift`

| Feld | Typ | Bedeutung |
|---|---|---|
| `id` | `UUID` | bei der Erzeugung vergeben, rein flüchtig |
| `ext` | `String` | Endung in Kleinschreibung, ohne Punkt. Leerer String für Dateien ohne Endung |
| `count` | `Int` | Anzahl Dateien mit dieser Endung |
| `totalBytes` | `Int64` | Summe der Dateigrößen |

Abgeleitet: `displayExt` (`.PNG` bzw. `(no extension)`), `formattedSize` über
`ByteCountFormatter`, `percentage(of:)` gegen eine übergebene Gesamtgröße.

`Hashable` und `==` stützen sich **allein auf `id`**. Zwei Gruppen mit identischer
Endung, Anzahl und Größe gelten damit als verschieden. Für die Verwendung in `Table`
und `ForEach` ist das richtig; als fachliche Gleichheit wäre es falsch — es wird
nirgends fachlich verglichen.

### `DateBucket` — ein Balken der Zeitachse

`Identifiable, Sendable` · `Sources/ScanEngine.swift`

| Feld | Typ | Bedeutung |
|---|---|---|
| `id` | `String` | zugleich der Fensterschlüssel, z. B. `Past Week` |
| `label` | `String` | Anzeigetext — identisch mit `id` |
| `fileCount` | `Int` | Dateien in diesem Zeitfenster |
| `totalBytes` | `Int64` | Volumen in diesem Zeitfenster |
| `sortIndex` | `Int` | 0–6, erzwingt die chronologische Reihenfolge und steuert die Einfärbung |

Die sieben Fenster stehen fest in `dateBucketKey(for:)`, gemessen in **ganzen Tagen
Abstand zum Änderungsdatum**:

| sortIndex | Schlüssel | Bedingung |
|---|---|---|
| 0 | `Future` | Änderungsdatum liegt in der Zukunft |
| 1 | `Today` | 0 Tage |
| 2 | `Past Week` | 1–7 Tage |
| 3 | `Past Month` | 8–30 Tage |
| 4 | `Past 3 Months` | 31–90 Tage |
| 5 | `Past Year` | 91–365 Tage |
| 6 | `Older` | älter |

`Future` ist im Code vorgesehen, taucht aber weder in `CHANGELOG.md` noch auf der
Website auf — dort werden sechs Fenster genannt. Dateien mit falsch gesetztem
Zeitstempel landen sichtbar in einem Balken, den die Dokumentation nicht kennt.

### `ScanResult` — das Ergebnis eines Durchlaufs

`Sendable`, wandert vom Hintergrund-Task zurück auf den Main Actor: `groups`,
`totalFiles`, `totalSize`, `dateBuckets`, `fileURLs`.

`fileURLs` enthält **jede einzelne gefundene Datei** und ist die Grundlage der
Duplikatsuche. Bei einem Ordner mit 200.000 Dateien liegen damit 200.000 `URL`-Objekte
im Speicher — der einzige Posten im Modell, der mit der Ordnergröße wächst. Eine obere
Schranke gibt es nicht.

### `DuplicateGroup` — Dateien mit identischem Inhalt

`Identifiable, Sendable` · `Sources/DuplicateDetector.swift`

| Feld | Typ | Bedeutung |
|---|---|---|
| `id` | `UUID` | flüchtig |
| `hash` | `String` | SHA-256 als Hex, 64 Zeichen |
| `fileSize` | `Int64` | Größe **einer** Kopie |
| `urls` | `[URL]` | alle Fundstellen, mindestens zwei |

Abgeleitet: `wastedBytes = fileSize × (Anzahl − 1)` — der Platz, der bei Behalten genau
einer Kopie frei würde.

### `ChartItem` — eine Diagrammscheibe

`Identifiable` · `Sources/ChartView.swift`. Reine Darstellungsstruktur: `id`, `label`,
`bytes`, `count`, `color`. Wird bei jedem Zugriff auf `chartData` neu berechnet, nie
gespeichert. Enthält als einzige Struktur eine Farbe — Modell und Darstellung sind hier
vermischt.

### `FileCategory` — die semantische Einordnung

`enum: String, CaseIterable, Identifiable, Sendable` · `Sources/FileCategory.swift`

Acht Fälle: `all`, `images`, `documents`, `videos`, `audio`, `code`, `archives`, `other`.
Je Fall ein SF-Symbol und eine feste Endungsmenge:

| Kategorie | Endungen | Anzahl |
|---|---|---|
| Images | jpg, jpeg, png, gif, bmp, tiff, tif, webp, svg, ico, heic, heif, raw, cr2, nef, psd, ai | 17 |
| Documents | pdf, doc, docx, xls, xlsx, ppt, pptx, txt, rtf, odt, ods, odp, pages, numbers, keynote, csv, md, epub | 18 |
| Videos | mp4, mov, avi, mkv, wmv, flv, webm, m4v, mpg, mpeg, 3gp, ts | 12 |
| Audio | mp3, wav, aac, flac, ogg, wma, m4a, aiff, aif, opus, mid, midi | 12 |
| Code | swift, py, js, ts, tsx, jsx, html, css, scss, json, xml, yaml, yml, sh, bash, zsh, rb, go, rs, c, cpp, h, hpp, java, kt, m, mm, sql, r, php, dart, lua, toml | 33 |
| Archives | zip, tar, gz, bz2, xz, 7z, rar, dmg, iso, pkg, deb, rpm, jar, war | 14 |
| All / Other | `nil` — Sonderbehandlung in `matches(ext:)` | — |

`all` trifft immer zu. `other` bildet bei **jedem einzelnen Aufruf** die Vereinigung
aller bekannten Endungen und prüft auf Nichtenthaltensein — 106 Endungen, neu
zusammengesetzt pro Zeile und pro Neuzeichnen.

Drei Beobachtungen zum Bestand, unverändert übernommen:

- `ts` steht bei **Videos** (MPEG Transport Stream) und bei **Code** (TypeScript). Bei
  überschneidenden Mengen entscheidet die Auswertungsreihenfolge, nicht die Absicht.
- `m` steht bei Code für Objective-C; MATLAB-Dateien teilen sich die Endung.
- Die Zuordnung ist rein an der Endung festgemacht. Der Inhalt wird nie geprüft — eine
  in `.png` umbenannte ZIP-Datei zählt als Bild.

### `ScanEngine` — der Zustand der Sitzung

`@Observable @MainActor` · zehn gespeicherte Eigenschaften: `groups`, `isScanning`,
`scannedFolderURL`, `totalFiles`, `totalSize`, `errorMessage`, `includeHidden`,
`selectedCategory`, `dateBuckets`, `scannedURLs`. Dazu drei berechnete —
`filteredGroups`, `filteredTotalFiles`, `filteredTotalSize` —, die den Kategoriefilter
anwenden.

Eine Instanz, erzeugt im `AppDelegate` und geteilt zwischen Hauptfenster und
Menüleisten-Kurzfassung. Beide sehen denselben Zustand; die Kurzfassung greift aber auf
die **ungefilterten** Felder zu.

## Ausgabeschemata

Die einzigen Daten, die den Prozess verlassen — beide nur auf ausdrückliche Nutzeraktion
über einen Systemdialog.

### CSV · `ExportManager.generateCSV`

```
Extension,Count,Size (Bytes),Size (Human),Percentage
".PNG",1240,58720256,"58,7 MB",42.1%
```

Spalten: `Extension` (in Anführungszeichen, innere Anführungszeichen verdoppelt),
`Count`, `Size (Bytes)`, `Size (Human)`, `Percentage` mit `%`-Zeichen und einer
Nachkommastelle. Exportiert wird die **gefilterte** Menge.

### JSON · `ExportManager.generateJSON`

| Feld | Typ | Inhalt |
|---|---|---|
| `scannedFolder` | String | **vollständiger Pfad** des gescannten Ordners |
| `scannedAt` | String | ISO 8601, Zeitpunkt des Exports — nicht des Scans |
| `totalFiles` | Int | gefilterte Gesamtzahl |
| `totalSizeBytes` | Int64 | gefilterte Gesamtgröße |
| `groups[]` | Array | `extension`, `count`, `sizeBytes`, `sizeHuman`, `percentage` |

Zwei Eigenheiten: `scannedFolder` enthält in der Regel den macOS-Benutzernamen (im PRD
unter *Datenschutz* vermerkt), und `scannedAt` beschreibt den Export, obwohl der Name
den Scan nahelegt.

## Löschregeln

| Datenart | Wo | Lebensdauer | Wie gelöscht |
|---|---|---|---|
| Scanergebnis, Dateiliste, Zeitfenster | Arbeitsspeicher | bis zum Neuscan oder Beenden | `ScanEngine.reset()` bzw. Prozessende |
| Duplikatergebnis | Arbeitsspeicher | bis zum nächsten Suchlauf | Überschreiben in `detect(urls:)` |
| Dateiinhalte beim Hashen | Arbeitsspeicher | ein 1-MB-Block | Blockweise verworfen, `autoreleasepool` je Durchlauf |
| `showMenubar` | `UserDefaults` | dauerhaft | nur durch Löschen der App-Domain |
| Exportierte CSV/JSON | vom Nutzer gewählter Ort | unbegrenzt | liegt außerhalb der Verantwortung der App |

Ein Konto- oder Datenexport im Sinne der DSGVO ist nicht erforderlich: Es gibt kein
Konto, und die einzigen Daten sind die Dateien des Nutzers selbst.

## Fehlbestand

| # | Beobachtung | Folge |
|---|---|---|
| DM-01 | `reset()` existiert, wird aber an keiner Stelle aufgerufen | Ein Zurücksetzen in den Leerzustand ist über die Oberfläche nicht erreichbar; die Methode ist toter Code |
| DM-02 | `scannedURLs` wächst unbeschränkt mit der Dateianzahl | Bei sehr großen Ordnern ist der Speicherverbrauch nicht abgeschätzt und nirgends begrenzt |
| DM-03 | Der zuletzt gescannte Ordner wird nicht persistiert | „Rescan" überlebt keinen Neustart. Mit Sandbox (Feature `01`) wären dafür Security-Scoped Bookmarks nötig — siehe FB-12 im PRD |
| DM-04 | `FileCategory.other` berechnet die Menge aller bekannten Endungen bei jedem Aufruf neu | 106 Endungen pro Zeile und Neuzeichnen; das gehört einmalig statisch berechnet |
| DM-05 | Das Zeitfenster `Future` ist implementiert, aber weder im CHANGELOG noch auf der Website dokumentiert | Ein Balken, den die Dokumentation nicht kennt |
| DM-06 | `ChartItem` trägt eine `Color` und vermischt damit Modell und Darstellung | Fällt erst auf, wenn die Diagrammfarben je Ansicht unterschiedlich sein sollen |
