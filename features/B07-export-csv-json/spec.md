# B07 · Export CSV und JSON — Spezifikation

Status: `review` · Stand: 2026-08-24 · geprüft, siehe `qa-report.md`

> Beschrieben ist, was der Bestand am 2026-08-23 tut — nicht, was er tun sollte.
> **Alle Kriterien in diesem Dokument beschreiben Verhalten, das so gewollt ist.**
> Was fragwürdig war, wurde am 2026-08-23 entschieden und steht im *Fehlbestand*.

## Zweck

Die Aufschlüsselung nach Dateityp lässt sich als CSV für die Tabellenkalkulation oder
als JSON für die Weiterverarbeitung speichern. Es ist der einzige Weg, auf dem Daten
die Anwendung verlassen.

## Abhängigkeiten

| Braucht | Status | Warum |
|---|---|---|
| B01 · Ordner scannen | `rekonstruiert` | liefert die Daten |
| B02 · Aufschlüsselung nach Dateityp | `bestand` | exportiert wird genau deren Inhalt |

## User Stories

- **US-01** · Als Nutzer möchte ich die Aufschlüsselung als CSV speichern, um sie in
  Numbers oder Excel weiterzuverwenden.
- **US-02** · Als Nutzer möchte ich sie als JSON speichern, um sie in einem Skript
  auszuwerten.
- **US-03** · Als Nutzer möchte ich selbst bestimmen, wohin gespeichert wird.

## Nicht im Scope

- **Export der einzelnen Dateien** — exportiert wird die Zusammenfassung je Endung,
  nie die Dateiliste.
- **Export der Duplikatergebnisse** (B06) und der Zeitachse (B05).
- **Automatischer oder geplanter Export.**

## Akzeptanzkriterien

### Auslösen

- **AK-01** · Angenommen, ein Ergebnis liegt vor, wenn das Menü „Export" geöffnet wird,
  dann stehen dort „Export CSV" und „Export JSON".
- **AK-02** · Angenommen, die gefilterte Menge ist leer, wenn die Werkzeugleiste
  gezeichnet wird, dann ist das Menü „Export" ausgegraut.
- **AK-03** · Angenommen, ein Format wird gewählt, wenn der Speichern-Dialog erscheint,
  dann ist der Name mit `FileScope_<Ordnername>.<endung>` vorbelegt und der Dateityp
  auf CSV bzw. JSON eingeschränkt.
- **AK-04** · Angenommen, der Speichern-Dialog wird abgebrochen, wenn er sich schließt,
  dann wird nichts geschrieben und nichts gemeldet.
- **AK-05** · Angenommen, ein Kategoriefilter ist gesetzt, wenn exportiert wird, dann
  enthält die Datei **nur die gefilterten Gruppen** und die dazu passenden Summen.

### CSV

- **AK-06** · Angenommen, eine CSV wird erzeugt, wenn die erste Zeile geschrieben wird,
  dann lautet sie `Extension,Count,Size (Bytes),Size (Human),Percentage`.
- **AK-07** · Angenommen, eine Gruppe wird geschrieben, wenn die Zeile entsteht, dann
  enthält sie die Endung in Anführungszeichen und in der Anzeigeform (`".PNG"` bzw.
  `"(no extension)"`), die Anzahl, die Größe in Bytes, die lesbare Größe in
  Anführungszeichen und den Anteil mit einer Nachkommastelle und Prozentzeichen.
- **AK-08** · Angenommen, eine Endung enthält ein Anführungszeichen, wenn sie
  geschrieben wird, dann wird es nach CSV-Regel verdoppelt.
- **AK-09** · Angenommen, die Datei wird geschrieben, wenn die Kodierung festgelegt
  wird, dann ist es UTF-8.

### JSON

- **AK-10** · Angenommen, eine JSON-Datei wird erzeugt, wenn sie geschrieben wird, dann
  enthält sie auf oberster Ebene `scannedFolder`, `scannedAt`, `totalFiles`,
  `totalSizeBytes` und `groups`.
- **AK-11** · Angenommen, eine Gruppe wird geschrieben, wenn ihr Objekt entsteht, dann
  enthält es `extension`, `count`, `sizeBytes`, `sizeHuman` und `percentage`.
- **AK-12** · Angenommen, die Datei wird erzeugt, wenn sie formatiert wird, dann ist sie
  eingerückt und die Schlüssel sind alphabetisch sortiert.
- **AK-13** · Angenommen, ein Anteil wird geschrieben, wenn er gerundet wird, dann auf
  eine Nachkommastelle.

### Fehler

- **AK-14** · Angenommen, das Schreiben schlägt fehl, wenn der Fehler auftritt, dann
  erscheint ein Hinweis „Export Failed" mit der Systemmeldung.
- **AK-15** · Angenommen, eine Datei gleichen Namens existiert am Zielort, wenn
  gespeichert wird, dann fragt der Systemdialog vor dem Überschreiben.

### Zu Fehlern erklärt — nicht mehr als Kriterium geführt

Die Nummern **AK-16, AK-17, AK-18, AK-19** beschrieben Verhalten, das der Code tatsächlich zeigt, und
waren als ⚠-Kriterien aufgenommen. Am 2026-08-23 wurden sie als **Fehler** eingestuft und
in den *Fehlbestand* überführt. Die Nummern bleiben unbesetzt, damit Verweise aus
`design.md` und aus späteren Berichten eindeutig bleiben.

**Für `sdd-qa` heißt das:** keine zu bestätigenden Kriterien, sondern eine Suchliste.

## Edge Cases

- **EC-01** · Kein Schreibrecht am Zielort → „Export Failed" mit Systemmeldung.
- **EC-02** · Kein Ordner gescannt → Menü ausgegraut, nicht erreichbar.
- **EC-03** · Gesamtgröße 0 → `percentage(of:)` liefert 0, keine Division durch null.
- **EC-04** · Dateiendung mit Sonderzeichen → wird durch die Anzeigeform und die
  Anführungszeichen abgefangen.
- **EC-05** · CSV in Excel geöffnet → ohne BOM kann Excel UTF-8 falsch deuten;
  Umlaute in Endungen erscheinen dann verstümmelt.
- **EC-06** · Sehr viele Endungen → keine Größenbeschränkung, die Datei wird entsprechend
  groß.

## Fehlbestand

- **FB-B07-01 · Stiller Datenverlust bei fehlgeschlagener JSON-Erzeugung.** Siehe AK-17.
  Folge: Der Nutzer glaubt, exportiert zu haben, und hält eine leere Datei in der Hand.

- **FB-B07-02 · Kein BOM in der CSV.** Folge: Excel unter Windows deutet UTF-8 nicht
  zuverlässig.

- **FB-B07-03 · Gemischte Zahlenformate in der CSV.** Siehe AK-18. Folge: Tabellen-
  programme lesen eine der beiden Spalten als Text statt als Zahl.

- **FB-B07-04 · `scannedAt` benennt den falschen Zeitpunkt.** Siehe AK-16.

- **FB-B07-05 · Kein Hinweis auf den enthaltenen Pfad.** Siehe AK-19 und DZ-04.

- **FB-B07-06 · Der Speichern-Dialog läuft modal über `runModal()`.**
  `ExportManager.swift:73`. Folge: blockiert den Main Actor; ein währenddessen fertig
  werdender Scan erscheint verzögert.

- **FB-B07-07 · Kein Test.** Die Erzeugung von CSV und JSON ist reine Zeichenketten-
  arbeit ohne Systemabhängigkeit — der am einfachsten prüfbare Teil der ganzen
  Anwendung, und ungeprüft.

### Aus Kriterien zu Fehlern erklärt (2026-08-23)

- **war AK-16** · Angenommen, eine JSON-Datei wird exportiert, wenn `scannedAt`
  geschrieben wird, dann steht dort der Zeitpunkt des **Exports**, nicht des Scans.
  *(`ExportManager.swift:38-39` bildet den Zeitstempel beim Erzeugen des Textes. Der
  Feldname legt etwas anderes nahe; der Scan kann Stunden zurückliegen. Zur Klärung
  vorgelegt.)*

- **war AK-17** · Angenommen, die JSON-Erzeugung schlägt fehl, wenn die Datei geschrieben
  wird, dann enthält sie `{}` — und der Nutzer bekommt **keine Fehlermeldung**.
  *(`ExportManager.swift:59-62` — der Rückfallwert `"{}"` wird wie ein gültiges Ergebnis
  gespeichert. Die Meldung aus AK-14 greift nur bei Schreibfehlern, nicht bei
  Serialisierungsfehlern. Am 2026-08-23 als Fehler eingestuft.)*

- **war AK-18** · Angenommen, exportiert wird auf einem System mit deutscher
  Spracheinstellung, wenn die CSV entsteht, dann steht in `Size (Human)` ein Komma als
  Dezimaltrennzeichen (`"58,7 MB"`) und in `Percentage` ein Punkt (`42.1%`) — **zwei
  verschiedene Trennzeichen in derselben Datei**.
  *(`ByteCountFormatter` folgt der Systemsprache, `String(format: "%.1f")` nicht. Zur
  Klärung vorgelegt.)*

- **war AK-19** · Angenommen, eine JSON-Datei wird weitergegeben, wenn sie geöffnet wird,
  dann enthält `scannedFolder` den **vollständigen Pfad** und damit in aller Regel den
  macOS-Benutzernamen — ohne Hinweis in der Oberfläche.
  *(Siehe DZ-04 in `docs/datenschutz.md`. Am 2026-08-23 als Fehler eingestuft.)*

## Offene Fragen

- **OF-01** · ~~Soll `scannedAt` den Scanzeitpunkt tragen?~~
  **Ja, umgesetzt am 2026-08-24.** `ScanEngine` hält den Zeitpunkt des Durchlaufs; der Export reicht ihn durch. Ein Test prüft es.

## Decision Log

| # | Frage | Entscheidung | Begründung |
|---|---|---|---|
| 1 | Welche Formate? | CSV und JSON | CSV für Menschen und Tabellen, JSON für Skripte. Deckt beide Nutzungsarten ohne dritte Abhängigkeit |
| 2 | Wohin wird gespeichert? | `NSSavePanel`, der Nutzer entscheidet | Ohne Sandbox wäre auch ein fester Ort möglich gewesen; der Dialog ist die auf macOS erwartete Form |
| 3 | Was wird exportiert? | die **gefilterte** Menge | Folgt dem, was der Nutzer gerade sieht. Konsistent mit Tabelle, Diagrammen und Kennzahlen — und das einzige Feature neben diesen, das dem Filter tatsächlich folgt |
| 4 | `enum` mit statischen Methoden statt Klasse | Instanz mit Zustand | Der Export hat keinen Zustand. Sauber |
| 5 | JSON von Hand über `JSONSerialization` | `Codable` | **Grund nicht erkennbar.** `Codable` hätte den Rückfall auf `"{}"` (FB-B07-01) unnötig gemacht |
| — | Sind die ⚠-Kriterien gewolltes Verhalten? | **Nein, 4 davon sind Fehler** (2026-08-23) | Gebündelt entschieden über alle Features hinweg; die Muster stehen in `features/index.md` |
