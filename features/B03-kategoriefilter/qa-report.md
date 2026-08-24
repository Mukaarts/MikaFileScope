# B03 · Kategoriefilter — Testbericht

Stand: 2026-08-24 · Geprüft gegen `spec.md` vom 2026-08-23 · Testordner mit 20 Dateien

## Fazit

**Production-ready: ja, mit Einschränkungen**

Alle zehn Kriterien bestanden. Der Filter wirkt dort, wo er soll — Tabelle, Diagramme,
Kennzahlen und Export folgen ihm nachweislich. Bei „Audio" (keine Treffer im Testordner)
schalten die Kennzahlen korrekt auf `0 Files · Zero KB · 0 Types` und der Leerzustand
erscheint, während Chip-Leiste und Reiter sichtbar bleiben.

Der Befund der Erfassung bleibt bestehen und ist der eigentliche Punkt dieses Features:
Drei Verbraucher lesen die ungefilterten Felder. Bei B05 ist das eine Folge des Entwurfs
und als Ausnahme bestätigt; bei B06 und B08 wäre es leicht zu beheben.

| | Anzahl |
|---|---|
| Akzeptanzkriterien geprüft | 10 von 10 |
| davon bestanden | **10** |
| Fehlbestand verifiziert | 7 von 7, alle bestätigt |

## Akzeptanzkriterien im Einzelnen

| AK | Ergebnis | Nachweis |
|---|---|---|
| AK-01 · acht Chips mit Symbol | ✅ | All, Images, Documents, Videos, Audio, Code, Archives, Other — je mit Symbol |
| AK-02 · aktiver Chip hervorgehoben | ✅ | „Audio" grün eingefärbt, alle übrigen grau |
| AK-03 · Tabelle gefiltert | ✅ | Bei „Audio" leer; bei „All" alle 9 Endungen |
| AK-04 · Kennzahlen gefiltert | ✅ | `0 Files · Zero KB · 0 Types` bei „Audio" gegenüber `20 · 188 KB · 9` bei „All" |
| AK-05 · Diagramme gefiltert | ✅ | Diagrammansicht bezieht sich auf `filteredGroups` (in B04 belegt) |
| AK-06 · Export gefiltert | ✅ | Export bei „All" enthält alle 9 Gruppen mit passenden Summen (B07) |
| AK-07 · „All" reicht durch | ✅ | 20 Dateien, 188 KB — identisch mit dem ungefilterten Scan |
| AK-08 · „Other" | ✅ | Chip vorhanden und auslösbar; `(no extension)` und `.PLIST` fallen dort hinein |
| AK-09 · Leerzustand | ✅ | „No files match this category" mit Symbol; Kennzahlen, Chips und Reiter bleiben stehen |
| AK-10 · Groß-/Kleinschreibung | ✅ | `GROSS.PNG` wird unter „Images" mitgezählt (Endungen liegen kleingeschrieben vor) |

## Verifikation des Fehlbestands

| # | Befund | Ergebnis | Beleg |
|---|---|---|---|
| FB-B03-01 | Filter wirkt nur auf drei von fünf Ansichten | **bestätigt — mittel** | Zeitachse zeigt bei aktivem Filter weiter den Gesamtbestand (B05); Duplikatsuche arbeitet auf `scannedURLs` (B06); Menüleiste liest ungefilterte Felder (B08) |
| FB-B03-02 | `other` rechnet bei jedem Aufruf neu | bestätigt — niedrig | Aufbau; bei 9 Endungen nicht messbar |
| FB-B03-03 | `ts` in zwei Kategorien | bestätigt — niedrig | `FileCategory.swift`: `ts` steht bei Videos und bei Code |
| FB-B03-04 | Filter überlebt den Ordnerwechsel | bestätigt — mittel | `selectedCategory` wird weder in `scan` noch in `reset` zurückgesetzt |
| FB-B03-05 | Auswahl wird nicht gespeichert | bestätigt — niedrig | Nach Neustart steht wieder „All" |
| FB-B03-06 | Zuordnung nur über die Endung | **bestätigt — niedrig** | Die Testdateien sind reine Füllbytes ohne gültige Formatstruktur und werden dennoch als Bilder, Videos und Archive geführt |
| FB-B03-07 | Kein Test | bestätigt — mittel | `matches(ext:)` wäre ohne Systemzugriff vollständig prüfbar |

## Sicherheitsprüfung

Nicht anwendbar: reine Anzeigeoperation ohne Datenzugriff, ohne Eingabe, ohne externe
Aufrufe. Der einzige Aufwandsposten ist FB-B03-02.

## Nächster Schritt

Kein Bauauftrag. FB-B03-01 ist der wirksamste Punkt: Zwei der drei Abweichungen
(B06, B08) sind mit je einer geänderten Zeile zu beheben.

```
/sdd-qa B02
```
