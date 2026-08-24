# Features

Stand: 2026-08-23 · Stack-Profil: `swiftui-macos` · Artefaktpfad: `docs/`

Elf Bestandsfeatures, vollständig rückerfasst (`sdd-erfassen`, Phasen 1 und 2). Jedes hat
`spec.md` und `design.md`, die beschreiben, **was der Code tut** — nicht, was er tun
sollte. Dazu ein geplantes Feature ohne `B`-Präfix, das durch die volle Kette läuft.

| ID | Feature | Prio | Status | Abhängig von | Zuletzt |
|---|---|---|---|---|---|
| B01 | Ordner scannen | P0 | **review** | — | 2026-08-24 · 16/18 AK, keine hohen Befunde |
| B02 | Aufschlüsselung nach Dateityp | P0 | **review** | B01 | 2026-08-24 · 9/10 AK |
| B03 | Kategoriefilter | P1 | **review** | B01, B02 | 2026-08-24 · 10/10 AK |
| B04 | Diagramme | P0 | **review** | B01 | 2026-08-24 · 8/10 AK |
| B05 | Zeitachse | P1 | **review** | B01 | 2026-08-24 · 7/9 AK, Fenster exakt getroffen |
| B06 | Duplikatsuche | P1 | **review** | B01 | 2026-08-24 · 12/15 AK |
| B07 | Export CSV und JSON | P0 | **review** | B01, B02 | 2026-08-24 · **1 AK durchgefallen** |
| B08 | Menüleisten-Kurzfassung | P2 | **review** | B01 | 2026-08-24 · 7/12 AK, 5 nicht prüfbar |
| B09 | Automatische Updates | P1 | **review** | — | 2026-08-24 · BF-06 offen, an Feature 01 gekoppelt |
| B10 | Auslieferung und Signatur | P0 | **review** | B09 | 2026-08-24 · 14/14 AK, 1 neuer Befund |
| B11 | Marketing-Website | P2 | **review** | B10 | 2026-08-24 · 13/17 AK, live geprüft |
| 01 | Mac App Store | P1 | roadmap | B01, B09, B10 | — |

## Umfang der Erfassung

| ID | Feature | Kriterien | Befunde | Offene Fragen |
|---|---|---|---|---|
| B01 | Ordner scannen | 18 | 14 | 1 |
| B02 | Aufschlüsselung | 10 | 10 | 1 |
| B03 | Kategoriefilter | 10 | 12 | 2 |
| B04 | Diagramme | 10 | 11 | 1 |
| B05 | Zeitachse | 9 | 10 | 2 |
| B06 | Duplikatsuche | 15 | 13 | 2 |
| B07 | Export | 15 | 11 | 1 |
| B08 | Menüleiste | 12 | 11 | 2 |
| B09 | Automatische Updates | 12 | 11 | 2 |
| B10 | Auslieferung | 14 | 14 | 1 |
| B11 | Website | 17 | 14 | 2 |
| | **Summe** | **142** | **131** | **17** |

Dazu 39 Beobachtungen in den vier Grundlagendokumenten unter `docs/`.

**Alle ⚠-Kriterien sind geklärt.** Ursprünglich waren 44 Kriterien als fragwürdig
markiert — Verhalten, das der Code zeigt, dessen Absicht aber nirgends steht. Am
2026-08-23 wurden **43 davon als Fehler eingestuft** und in den *Fehlbestand* der
jeweiligen Spec überführt; ihre AK-Nummern bleiben unbesetzt, damit Verweise eindeutig
bleiben.

Die eine Ausnahme ist **B05 · AK-09**: Die Zeitachse folgt dem Kategoriefilter nicht.
Das bleibt ein reguläres Kriterium, weil es keine Nachlässigkeit ist, sondern eine Folge
des Entwurfs — die Zeitfenster werden bereits während des Scans verdichtet, ohne die
Endung mitzuführen. Eine Änderung griffe ins Datenmodell und in B01 ein.

**Damit gilt für `sdd-qa`:** Jedes verbliebene Kriterium beschreibt gewolltes Verhalten
und darf als bestanden gemeldet werden. Der Fehlbestand ist keine Prüfliste, sondern
eine Suchliste.

## Reihenfolge der Prüfung

Nach Risiko sortiert, nicht nach Nummer:

```
B09 → B10 → B01 → B06 → B07 → B11 → B03 → B02 → B05 → B04 → B08
```

| Rang | ID | Warum hier |
|---|---|---|
| 1 | **B09** | Einziger Weg, auf dem fremder Code auf fremde Rechner gelangt. Feed leer, Build-Nummer eingefroren, ausgelieferte Kopien fragen einen freigegebenen Kontonamen ab |
| 2 | **B10** | Bestimmt, was die Nutzer bekommen. Gatekeeper lehnt nachweislich ab (`spctl` → rejected), nur arm64, kein CI |
| 3 | **B01** | Liest den gesamten Dateibestand. Zählt Paketinhalte einzeln, verschluckt Lesefehler, kein Abbruch, paralleler Zweitscan möglich |
| 4 | **B06** | Liest Dateiinhalte vollständig. Fortschritt ohne Fortschritt, Hardlinks als rückgewinnbarer Platz gemeldet |
| 5 | **B07** | Einziger Datenausgang. Stiller Datenverlust bei fehlgeschlagener JSON-Erzeugung |
| 6 | **B11** | Öffentliche Zusagen. „Open source" ohne Lizenz, kein Impressum, keine Datenschutzerklärung bei `.lu`-Domain |
| 7 | **B03** | Ursache der Filter-Inkonsistenz in drei Nachbarfeatures |
| 8 | **B02** | Quadratischer Zeichenaufwand, Sortierung verändert geteilten Zustand |
| 9 | **B05** | Folgt dem Filter nicht — bestätigte Ausnahme, aber `Future` und leere Fenster bleiben Befunde |
| 10 | **B04** | Diagrammdaten dreifach berechnet, keine Interaktion, Grau doppeldeutig |
| 11 | **B08** | „Quick Scan", der nichts scannen kann |

## Muster über mehrere Features

Der eigentliche Ertrag einer Vollerfassung — was in mehreren Specs gleichzeitig auftaucht:

| Muster | Betrifft | Kern |
|---|---|---|
| **Der Filter wirkt nur halb** | B03, B05, B06, B08, B11 | Vier Verbraucher lesen ungefilterte Felder. Bei B06 und B08 ist die Umstellung trivial, bei B05 unmöglich ohne Änderung am Datenmodell. Die Website verspricht durchgehende Wirkung |
| **Stille Fehlschläge** | B01, B06, B07, B08 | Lesefehler, Hash-Fehler, JSON-Fehler und Ablagefehler enden ohne Rückmeldung. Beim JSON-Export entsteht dabei eine leere Datei, die wie ein Erfolg aussieht |
| **Kein Abbruch, kein Fortschritt** | B01, B06 | Die beiden lang laufenden Operationen lassen sich weder anhalten noch beobachten |
| **Zählweise folgt dem Enumerator, nicht dem Nutzer** | B01, B06 | Pakete als hunderte Einzeldateien, Symlinks doppelt, Hardlinks als rückgewinnbarer Platz |
| **Dokumentation weicht vom Code ab** | B10, B11, alle | CI-Workflow beschrieben aber nicht vorhanden, CHANGELOG seit v1.0.0 nicht fortgeschrieben, Palette laut `CLAUDE.md` synchron und tatsächlich nicht, Sparkle-Version veraltet angegeben |
| **Kein einziger Test** | alle elf | Kein `Tests/`-Verzeichnis. Besonders bedauerlich bei reiner Rechenlogik wie `matches(ext:)`, `dateBucketKey` oder `generateCSV`, die ohne Systemzugriff prüfbar wäre |
| **Zwei Fassungen derselben Sache** | B02/B08, B04/B05 | `StatPill` neben `miniStat`; die Farbwerte `148/0.70/0.75` an zwei Stellen fest im Code |
| **Nur acht Farben** | B02, B04 | Ab Rang neun grau — in den Diagrammen bedeutet Grau aber „Other". Dieselbe Farbe, zwei Bedeutungen |

## Was nach der QA eines Bestandsfeatures passiert

| Ergebnis | Nächster Schritt | Status |
|---|---|---|
| kein Befund | kein Deployment — der Code ist live | `deployed`, mit Auditvermerk |
| kritisch oder hoch | Erfassung pausiert: `sdd-build` → `sdd-qa` → `sdd-deploy` | `review` → … → `deployed` |
| nur mittel oder niedrig | Eintrag in `features/befunde.md`, weiter mit dem nächsten | bleibt `review` |

## Sofortmaßnahme außerhalb der Kette

**Den GitHub-Kontonamen `Mukaarts` sichern** — beschlossen am 2026-08-23, Einzelheiten in
`features/B09-automatische-updates/spec.md`. Ausgelieferte Kopien von v2.0.0 fragen dort
ihren Update-Feed ab; der Name ist über die GitHub-API nicht mehr auffindbar und damit
vermutlich neu registrierbar. Die Maßnahme ändert keinen Code und gehört in den Betrieb,
nicht in einen Fehlerauftrag — und sie wirkt als einzige sofort, weil der Update-Kanal
selbst defekt ist.

## Nächster Schritt

```
/sdd-erfassen abschluss
```

B09 ist zweimal geprüft. Der erste Durchlauf (2026-08-23) fand fünf Fehler, die Reparatur
(2026-08-24, Zweig `fix/b09-update-kanal`) behob vier davon nachweislich. Der zweite
Durchlauf bestätigte das — und fand **BUG-06**: Die Installation eines Updates schlägt
fehl. Angeboten und heruntergeladen wird, dann bricht Sparkle ab; in drei Varianten
reproduziert, Ursache nicht ermittelt.

Der Kanal ist damit weiterhin funktionsunfähig, nur an anderer Stelle: Erst wurde nichts
angeboten, jetzt wird angeboten, aber nicht installiert.

**Die Prüfung der übrigen Features bleibt ausgesetzt**, bis die Reparatur ausgeliefert
ist. Reihenfolge danach: `/sdd-qa B09` → `/sdd-deploy B09` → `/sdd-qa B10`. Der
Auditbericht über alle Prüfungen entsteht am Ende mit `/sdd-erfassen abschluss`.

**Außerhalb der Kette weiterhin dringend:** den GitHub-Kontonamen `Mukaarts` sichern.
Solange die Weiterleitung besteht, ist sie der einzige Weg, die Altbestände zu
erreichen — und sie endet, sobald jemand den Namen registriert.
