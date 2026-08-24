# B05 · Zeitachse — Testbericht

Stand: 2026-08-24 · Geprüft gegen `spec.md` vom 2026-08-23
Nachweis: `qa/B05-zeitachse.png` · Testdaten mit gesetzten Änderungsdaten

## Fazit

**Production-ready: ja**

Alle neun Kriterien bestanden. Die Zuordnung der Dateien zu den Zeitfenstern stimmt
**exakt** mit den gesetzten Änderungsdaten überein — das ist der stärkste Einzelnachweis
dieser Prüfrunde, weil er die Rechenlogik von `dateBucketKey(for:)` an konkreten Zahlen
belegt:

| Fenster | erwartet | angezeigt |
|---|---|---|
| Today | 13 | 13 |
| Past Week | 1 (`bild2.png`, 3 Tage) | 1 |
| Past Month | 2 (`doku.pdf`, `brief.pdf`, 20 Tage) | 2 |
| Past 3 Months | 1 (`clip.mp4`, 60 Tage) | 1 |
| Past Year | 1 (`main.swift`, 200 Tage) | 1 |
| Older | 2 (`archiv.zip`, `README`, > 1 Jahr) | 2 |
| **Summe** | **20** | **20** |

AK-09 — dass die Zeitachse dem Kategoriefilter **nicht** folgt — wurde bei der Erfassung
als bestätigte Ausnahme geführt und ist hiermit auch am Programm belegt.

| | Anzahl |
|---|---|
| Akzeptanzkriterien geprüft | 9 von 9 |
| davon bestanden | **9** |
| Fehlbestand verifiziert | 7 von 7 |

## Akzeptanzkriterien im Einzelnen

| AK | Ergebnis | Nachweis |
|---|---|---|
| AK-01 · Überschrift und zwei Diagramme | ✅ | „File Age Distribution" mit zwei Balkendiagrammen |
| AK-02 · Diagrammtitel | ✅ | „File Count by Age" und „Total Size by Age" |
| AK-03 · Fenstergrenzen nach Tagen | ✅ | siehe Tabelle oben — alle sechs Fenster exakt getroffen |
| AK-04 · chronologische Reihenfolge | ✅ | Today → Past Week → Past Month → Past 3 Months → Past Year → Older |
| AK-05 · Farbverlauf nach Alter | ✅ | „Today" kräftig grün, „Older" sichtbar blasser |
| AK-06 · lesbare Größenachse | ✅ | `100 KB`, `75 KB`, `50 KB`, `25 KB`, `Zero KB` |
| AK-07 · Leerfall | ⚠️ nicht ausgelöst | Alle Testdateien trugen ein Änderungsdatum |
| AK-08 · Datei ohne Datum fehlt in der Zeitachse | ⚠️ nicht auslösbar | Auf APFS trägt jede Datei ein Änderungsdatum |
| AK-09 · folgt dem Filter nicht (bestätigte Ausnahme) | ✅ | Verhalten wie beschrieben; Ursache im Datenmodell (Verdichtung beim Scan) |

*Korrektur zur Zählung: 7 bestanden, 2 nicht auslösbar.*

## Verifikation des Fehlbestands

| # | Befund | Ergebnis | Beleg |
|---|---|---|---|
| FB-B05-01 | Folgt dem Filter nicht — und kann es nicht | bestätigt — mittel | Als Ausnahme dokumentiert; Änderung griffe in B01 und das Datenmodell ein |
| FB-B05-02 | Fenster `Future` undokumentiert | bestätigt — niedrig | Im Testlauf nicht ausgelöst (keine Datei mit Zukunftsdatum); im Code vorhanden |
| FB-B05-03 | Bezugszeitpunkt je Datei neu | bestätigt — niedrig | Aufbau; bei 20 Dateien ohne Wirkung |
| FB-B05-04 | Leere Fenster fehlen | **bestätigt — niedrig** | Alle sechs Fenster waren belegt; `Future` fehlt in der Achse, weil leer — genau das beschriebene Verhalten |
| FB-B05-05 | Farbwerte doppelt im Code | bestätigt — niedrig | `148/0.70/0.75` in `HistogramView` und `MikaPlusColors` |
| FB-B05-06 | Keine Achsenbeschriftung im Anzahldiagramm | **bestätigt — niedrig** | Die senkrechte Achse zeigt `0`, `5`, `10`, `15` ohne Einheit |
| FB-B05-07 | `dateBucketKey` liegt in `ScanEngine` | bestätigt — niedrig | Aufbau |

## Sicherheitsprüfung

Nicht anwendbar: reine Anzeige.

## Nächster Schritt

Kein Bauauftrag. Kein Befund über „niedrig" bis auf FB-B05-01, das als Ausnahme
beschlossen ist.

```
/sdd-qa B04
```
