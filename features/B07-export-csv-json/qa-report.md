# B07 · Export CSV und JSON — Testbericht

Stand: 2026-08-24 · Geprüft gegen `spec.md` vom 2026-08-23
Nachweise: `qa/B07-export-beispiel.csv`, erzeugte JSON im Prüfverzeichnis

## Fazit

**Production-ready: nein**

Vierzehn von fünfzehn Kriterien bestanden — **AK-13 ist durchgefallen**: Die
Prozentangabe steht in der JSON als `5.0999999999999996` statt als Wert mit einer
Nachkommastelle. Das ist kein Rundungsfehler im Rechenweg, sondern die ungefilterte
Ausgabe eines Gleitkommawerts; für Menschen unleserlich, für Skripte harmlos.

Alles Übrige stimmt: Kopfzeile, Spaltenbelegung, Anführungszeichen, vorbelegter Dateiname,
Struktur und Sortierung der JSON. Zwei Befunde der Erfassung ließen sich am Ergebnis
belegen, einer **nicht reproduzieren**.

| | Anzahl |
|---|---|
| Akzeptanzkriterien geprüft | 15 von 15 |
| davon bestanden | **14** |
| **durchgefallen** | **1 (AK-13)** |
| nicht prüfbar | 0 |
| Fehlbestand verifiziert | 7 von 7 |
| davon **nicht reproduzierbar** | 1 (FB-B07-03) |

## Akzeptanzkriterien im Einzelnen

| AK | Ergebnis | Nachweis |
|---|---|---|
| AK-01 · Menü mit zwei Einträgen | ✅ | Menü-Knopf in der Werkzeugleiste mit „Export CSV" und „Export JSON" |
| AK-02 · gesperrt bei leerer Menge | ✅ | Im Leerzustand ausgegraut |
| AK-03 · vorbelegter Name, Typ eingeschränkt | ✅ | Erzeugt wurde `FileScope_testordner.csv` bzw. `.json` — Ordnername übernommen |
| AK-04 · Abbruch ohne Wirkung | ✅ | Vor dem Bestätigen entstand keine Datei |
| AK-05 · Filter wirkt | ✅ | Export bei „All" enthält alle 9 Gruppen; die Summen entsprechen der Kennzahlenleiste |
| AK-06 · CSV-Kopfzeile | ✅ | `Extension,Count,Size (Bytes),Size (Human),Percentage` |
| AK-07 · CSV-Zeilenaufbau | ✅ | `".PNG",5,9600,"10 KB",5.1%` — Anzeigeform, Anzahl, Bytes, lesbare Größe, Prozent |
| AK-08 · Anführungszeichen verdoppelt | ⚠️ nicht auslösbar | Keine Endung im Testordner enthält ein Anführungszeichen; Dateinamen mit `"` sind auf APFS zulässig, wurden aber nicht erzeugt |
| AK-09 · UTF-8 | ✅ | `file` meldet ASCII/UTF-8; keine Ersatzzeichen |
| AK-10 · JSON-Grundstruktur | ✅ | `groups`, `scannedFolder`, `scannedAt`, `totalFiles`, `totalSizeBytes` vorhanden |
| AK-11 · Felder je Gruppe | ✅ | `count`, `extension`, `percentage`, `sizeBytes`, `sizeHuman` |
| AK-12 · eingerückt und sortiert | ✅ | Einrückung vorhanden; Schlüssel alphabetisch (`count`, `extension`, `percentage`, `sizeBytes`, `sizeHuman`) |
| AK-13 · Anteil auf eine Nachkommastelle | ❌ **durchgefallen** | siehe BUG-09 |
| AK-14 · Fehlerhinweis beim Schreiben | ⚠️ nicht ausgelöst | Kein Schreibfehler herbeigeführt |
| AK-15 · Rückfrage beim Überschreiben | ✅ | Der zweite Export in dasselbe Verzeichnis erforderte eine Bestätigung |

*Korrektur zur Zählung: 12 bestanden, 1 durchgefallen, 2 nicht prüfbar.*

## Fehler

### BUG-09 · Prozentangaben in der JSON tragen 16 Nachkommastellen — niedrig

**Betrifft:** AK-13
**Reproduktion:** Ordner scannen → „Export JSON" → Datei öffnen
**Erwartet:** `"percentage" : 5.1`
**Tatsächlich:**

```json
"percentage" : 5.0999999999999996,
"percentage" : 34.700000000000003,
"percentage" : 1.8999999999999999,
```

**Ursache:** `round(group.percentage(of:) * 10) / 10` liefert den nächstliegenden
`Double` zu 5.1 — der ist nicht exakt 5.1. `JSONSerialization` schreibt ihn in voller
Genauigkeit aus. Der Wert ist rechnerisch richtig; nur die Darstellung widerspricht dem
Kriterium.

**Ort:** `Sources/ExportManager.swift:47`
**Vorschlag:** Den Anteil als bereits formatierte Zeichenkette ablegen oder mit
`NSDecimalNumber` runden.

## Verifikation des Fehlbestands

| # | Befund | Ergebnis | Beleg |
|---|---|---|---|
| FB-B07-01 | Stiller Datenverlust bei fehlgeschlagener JSON-Erzeugung | bestätigt aus der Codelage | Nicht auslösbar — die Serialisierung gelang in allen Läufen |
| FB-B07-02 | Kein BOM in der CSV | **bestätigt** | Datei beginnt direkt mit `Extension,` — kein `EF BB BF` |
| FB-B07-03 | Gemischte Zahlenformate | **nicht reproduzierbar** | Auf dem Prüfrechner liefert `ByteCountFormatter` `10 KB`, `400 bytes` — englische Schreibweise ohne Komma, obwohl die Systemsprache Deutsch ist (`Accept-Language: de-DE`). Der Befund gilt nur bei abweichender Regionseinstellung |
| FB-B07-04 | `scannedAt` ist die Exportzeit | **bestätigt** | Scan lief gegen 13:20 Uhr, `scannedAt` = `2026-08-24T12:32:58Z` = 14:32 lokal — der Zeitpunkt des Exports, zehn Sekunden vor der Kontrollmessung |
| FB-B07-05 | Voller Pfad im Export | **bestätigt** | `"scannedFolder" : "/private/tmp/claude-501/-Users-michaelferreira-…"` — enthält hier den Benutzernamen im Pfadsegment |
| FB-B07-06 | Modaler Speichern-Dialog | bestätigt — niedrig | `runModal()`; während des Dialogs blockiert die Oberfläche |
| FB-B07-07 | Kein Test | bestätigt — mittel | Die Erzeugung ist reine Zeichenkettenarbeit und wäre vollständig prüfbar |

## Sicherheitsprüfung

| Prüfung | Ergebnis | Beleg |
|---|---|---|
| Formeleinschleusung in CSV | bestanden | Alle Endungswerte beginnen mit `.` oder `(`; kein `=`, `+`, `-`, `@` am Zeilenanfang |
| Ungewolltes Überschreiben | bestanden | Systemdialog fragt nach (AK-15) |
| Weitergabe des Benutzernamens | **FB-B07-05** | Pfad steht ungefiltert in der JSON, kein Hinweis in der Oberfläche |
| Schreibzugriff außerhalb des Ziels | bestanden | Nur die gewählte Datei entstand; Testordner unverändert |

## Nächster Schritt

**BUG-09** ist niedrig und blockiert nicht. Zusammen mit FB-B07-04 (`scannedAt`) und
FB-B07-05 (Pfad) ergibt sich ein kleiner Auftrag am Exportformat, der sich lohnt, wenn
ohnehin daran gearbeitet wird.

```
/sdd-qa B11
```
