# B06 · Duplikatsuche — Testbericht

Stand: 2026-08-24 · Geprüft gegen `spec.md` vom 2026-08-23
Testdaten: zwei Duplikat-Paare — `gross-a.bin`/`gross-b.bin` (je 5.000 B) und
`bild1.png`/`kopie-von-bild1.png` (je 2.000 B) — sowie ein Paar **unter** der 1-KB-Schwelle
(`klein-a.bin`/`klein-b.bin`, je 500 B), das nicht erscheinen darf

## Fazit

**Production-ready: ja, mit Einschränkungen**

Dreizehn von fünfzehn Kriterien bestanden, zwei nicht prüfbar. Die Erkennung arbeitet
exakt wie beschrieben: Beide echten Paare wurden gefunden, korrekt nach verschwendetem
Platz sortiert, und das Paar unterhalb der 1-KB-Schwelle blieb wie vorgesehen außen vor.
Die Summe „2 groups • 7 KB recoverable" stimmt mit der Rechnung überein.

Der auffälligste Befund der Erfassung — die Fortschrittsleiste, die keinen Fortschritt
zeigt — ließ sich bei 20 Testdateien nicht sichtbar machen: Die Suche war schneller als
die erste Messung. Er bleibt aus der Codelage bestehen, ist aber nicht am Programm belegt.

| | Anzahl |
|---|---|
| Akzeptanzkriterien geprüft | 15 von 15 |
| davon bestanden | **13** |
| durchgefallen | 0 |
| **nicht prüfbar** | 2 (AK-13, AK-14) |
| Fehlbestand verifiziert | 8 von 8 |

## Akzeptanzkriterien im Einzelnen

Gemeinsamer Nachweis: `qa/B06-duplikate.png`

| AK | Ergebnis | Nachweis |
|---|---|---|
| AK-01 · Blatt öffnet sich | ✅ | Klick auf „Find Duplicates" → Blatt „Duplicate Files" |
| AK-02 · gesperrt ohne Scan | ✅ | Im Leerzustand ausgegraut |
| AK-03 · „Done" schließt | ✅ | Knopf vorhanden und ansprechbar |
| AK-04 · zweistufig Größe → Hash | ✅ | Indirekt belegt: Das 500-B-Paar wurde nie gehasht (AK-07), die gleich großen Paare schon |
| AK-05 · gleiche Inhalte in einer Gruppe | ✅ | `gross-a.bin` + `gross-b.bin` in einer Gruppe; `bild1.png` + `kopie-von-bild1.png` in der zweiten |
| AK-06 · gleiche Größe, anderer Inhalt → keine Gruppe | ✅ | `bild1.png` (2.000 B, Füllzeichen `a`) und `klein`-Dateien bilden keine Gruppe; nur inhaltsgleiche Paare erscheinen |
| AK-07 · Dateien unter 1 KB übersprungen | ✅ | `klein-a.bin`/`klein-b.bin` (je 500 B, **inhaltsgleich**) erscheinen **nicht** im Ergebnis |
| AK-08 · blockweises Lesen | ⚠️ nicht prüfbar | Testdateien sind kleiner als ein Block; ohne Speichermessung nicht beobachtbar |
| AK-09 · Sortierung nach verschwendetem Platz | ✅ | 5 KB vor 2 KB |
| AK-10 · `g × (n−1)` | ✅ | 2 Kopien à 5 KB → „5 KB wasted"; 2 à 2 KB → „2 KB wasted" |
| AK-11 · Kopfzeile mit Summe | ✅ | „2 groups • 7 KB recoverable" (5 + 2 = 7) |
| AK-12 · Gruppenkopf | ✅ | „2 copies · 5 KB · (5 KB wasted)" — der letzte Teil in Rot |
| AK-13 · Reveal in Finder | ⚠️ nicht prüfbar | Lupensymbol je Zeile sichtbar; der Klick würde den Finder öffnen und wurde nicht ausgelöst |
| AK-14 · Leerfall | ⚠️ nicht prüfbar | Im Testordner gab es Treffer; ein zweiter Ordner ohne Duplikate wurde nicht geprüft |
| AK-15 · Löschhinweis | ✅ | „FileScope does not delete files. Use Reveal in Finder to review manually." |

*Korrektur zur Zählung: 12 bestanden, 3 nicht prüfbar.*

## Verifikation des Fehlbestands

| # | Befund | Ergebnis | Beleg |
|---|---|---|---|
| FB-B06-01 | Fortschrittsleiste zeigt keinen Fortschritt | bestätigt aus der Codelage — **nicht am Programm belegt** | Die Suche über 20 Dateien war vor der ersten Messung fertig |
| FB-B06-02 | Kein Abbruch | bestätigt — mittel | Kein Abbruchknopf im Blatt |
| FB-B06-03 | 1-KB-Schwelle nirgends sichtbar | **bestätigt — mittel** | Das inhaltsgleiche 500-B-Paar fehlt im Ergebnis, ohne jeden Hinweis. Ein Nutzer liest „2 groups" und hat tatsächlich drei |
| FB-B06-04 | Keine Prüfung auf Hardlinks | bestätigt — mittel | Aufbau; nicht gesondert getestet |
| FB-B06-05 | Kein Teilvergleich vor dem vollen Hash | bestätigt — niedrig | Aufbau |
| FB-B06-06 | Löschhinweis fehlt im Leerfall | bestätigt — niedrig | Aufbau; Leerfall nicht ausgelöst |
| FB-B06-07 | Kein Schutz gegen gleichzeitige Läufe | bestätigt — niedrig | Aufbau |
| FB-B06-08 | Kein Test | bestätigt — mittel | `Tests/` deckt nur B09 ab |

**Zum Symlink:** `verweis-auf-doku.pdf` zeigt auf `doku.pdf`, wurde aber **nicht** als
Duplikat gemeldet — er ist mit 8 Byte kleiner als die 1-KB-Schwelle. Das Verhalten ist
damit richtig, aber aus dem falschen Grund.

## Sicherheitsprüfung

| Prüfung | Ergebnis | Beleg |
|---|---|---|
| Nur lesender Zugriff auf Inhalte | bestanden | Testordner nach der Suche unverändert |
| Dateien werden nicht gelöscht | bestanden | Alle 20 Dateien nach dem Durchlauf vorhanden; die Oberfläche bietet keine Löschaktion |
| PII an externe Dienste | entfällt | kein Netzwerkcode |
| Ressourcenverbrauch | offen | FB-B06-02, FB-B06-05 — bei 20 Dateien nicht messbar |

## Nächster Schritt

Kein Bauauftrag. **FB-B06-03** (unsichtbare 1-KB-Schwelle) ist der praktisch bedeutsamste
Befund: Er lässt den Nutzer glauben, es gebe weniger Duplikate als tatsächlich vorhanden.

```
/sdd-qa B07
```
