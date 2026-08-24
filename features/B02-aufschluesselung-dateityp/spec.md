# B02 · Aufschlüsselung nach Dateityp — Spezifikation

Status: `review` · Stand: 2026-08-24 · geprüft, siehe `qa-report.md`

> Beschrieben ist, was der Bestand am 2026-08-23 tut — nicht, was er tun sollte.
> **Alle Kriterien in diesem Dokument beschreiben Verhalten, das so gewollt ist.**
> Was fragwürdig war, wurde am 2026-08-23 entschieden und steht im *Fehlbestand*.

## Zweck

Eine sortierbare Tabelle zeigt jede vorkommende Dateiendung mit Anzahl, Gesamtgröße und
Anteil am Ganzen, darüber eine Leiste mit drei Kennzahlen. Es ist die Hauptansicht der
App und der Reiter, der beim Start ausgewählt ist.

## Abhängigkeiten

| Braucht | Status | Warum |
|---|---|---|
| B01 · Ordner scannen | `rekonstruiert` | liefert die Gruppen |

## User Stories

- **US-01** · Als Nutzer möchte ich sehen, welcher Dateityp den meisten Platz belegt.
- **US-02** · Als Nutzer möchte ich nach Größe, Anzahl oder Endung sortieren, um
  verschiedene Fragen zu beantworten.
- **US-03** · Als Nutzer möchte ich den Anteil am Ganzen auf einen Blick erfassen, ohne
  zu rechnen.

## Nicht im Scope

- **Einzelne Dateien anzeigen** — die Tabelle führt Gruppen, nie Dateien.
- **Öffnen oder Auswählen** einer Zeile im Finder — nur B06 kann das.
- **Diagramme** — B04.

## Akzeptanzkriterien

- **AK-01** · Angenommen, ein Scan liegt vor, wenn der Reiter *List* aktiv ist, dann
  erscheint eine Tabelle mit den Spalten Extension, Count, Size und „% of Total".
- **AK-02** · Angenommen, die Tabelle erscheint, wenn sie zum ersten Mal gezeichnet
  wird, dann ist sie absteigend nach Anzahl sortiert.
- **AK-03** · Angenommen, eine Spaltenüberschrift wird gewählt, wenn sortiert wird, dann
  ordnet sich die Tabelle nach dieser Spalte um.
- **AK-04** · Angenommen, eine Zeile wird gezeichnet, wenn die Endungsspalte erscheint,
  dann steht links ein farbiger Balken (4 × 18 Punkt) und daneben die Endung in
  Festbreitenschrift als `.PNG` bzw. `(no extension)`.
- **AK-05** · Angenommen, eine Zeile wird gezeichnet, wenn die Anteilsspalte erscheint,
  dann zeigt sie einen Fortschrittsbalken in der Markenfarbe und den Wert mit einer
  Nachkommastelle und Prozentzeichen.
- **AK-06** · Angenommen, ein Kategoriefilter ist gesetzt, wenn Anteile berechnet
  werden, dann beziehen sie sich auf die **gefilterte** Gesamtgröße, nicht auf den
  gesamten Ordner.
- **AK-07** · Angenommen, Zahlen werden dargestellt, wenn sie sich ändern, dann springen
  sie nicht — Anzahl, Größe und Anteil verwenden Ziffern fester Breite.
- **AK-08** · Angenommen, ein Scan liegt vor, wenn die Kennzahlenleiste erscheint, dann
  zeigt sie drei Pillen: Files, Total Size, Types.
- **AK-09** · Angenommen, Größen werden angezeigt, wenn sie formatiert werden, dann
  geschieht das lesbar über die Systemformatierung (`58,7 MB`).
- **AK-10** · Angenommen, die Gesamtgröße ist 0, wenn ein Anteil berechnet wird, dann
  ergibt er 0 und es entsteht kein Rechenfehler.

### Zu Fehlern erklärt — nicht mehr als Kriterium geführt

Die Nummern **AK-11, AK-12, AK-13, AK-14** beschrieben Verhalten, das der Code tatsächlich zeigt, und
waren als ⚠-Kriterien aufgenommen. Am 2026-08-23 wurden sie als **Fehler** eingestuft und
in den *Fehlbestand* überführt. Die Nummern bleiben unbesetzt, damit Verweise aus
`design.md` und aus späteren Berichten eindeutig bleiben.

**Für `sdd-qa` heißt das:** keine zu bestätigenden Kriterien, sondern eine Suchliste.

## Edge Cases

- **EC-01** · Ein einziger Dateityp → eine Zeile, Anteil 100 %.
- **EC-02** · Sehr viele Endungen → die Tabelle scrollt; die Farbwiederholung aus AK-14
  wird deutlich sichtbar.
- **EC-03** · Alle Dateien 0 Byte → Anzahl korrekt, alle Anteile 0 %.
- **EC-04** · Neuscan mit anderem Ergebnis → die Sortierreihenfolge des Nutzers bleibt
  erhalten, weil `sortOrder` im View-Zustand liegt.

## Fehlbestand

- **FB-B02-01 · Quadratischer Aufwand beim Zeichnen.** Siehe AK-11. Folge: spürbar bei
  vielen Endungen, unnötig — die Zuordnung ließe sich einmal berechnen.

- **FB-B02-02 · Eine Spalte ist nicht sortierbar.** Siehe AK-12.

- **FB-B02-03 · Die Sortierung verändert den gemeinsamen Zustand.** Siehe AK-13. Folge:
  Die Reihenfolge in der Menüleisten-Kurzfassung ändert sich mit, obwohl sie dort
  ohnehin neu sortiert wird — heute folgenlos, aber eine verdeckte Kopplung.

- **FB-B02-04 · Nur acht Farben für beliebig viele Zeilen.** Siehe AK-14.

- **FB-B02-05 · `StatPill` ist privat und wird nicht geteilt.** Die Menüleisten-
  Kurzfassung baut mit `miniStat` eine zweite, optisch abweichende Fassung derselben
  Sache (DS-07).

- **FB-B02-06 · Keine Barrierefreiheitsangaben.** Der farbige Balken und der
  Fortschrittsbalken tragen keine Beschriftung; für Bedienungshilfen bleibt der Anteil
  nur als Text zugänglich.

### Aus Kriterien zu Fehlern erklärt (2026-08-23)

- **war AK-11** · Angenommen, die Tabelle wird gezeichnet, wenn die Farbe einer Zeile
  bestimmt wird, dann wird dafür **die gesamte gefilterte Liste neu sortiert** — einmal
  pro Zeile.
  *(`ContentView.swift:343-350` — `colorForGroup` sortiert `filteredGroups` und sucht
  darin den Index. Bei 200 Endungen sind das 200 Sortierläufe je Neuzeichnen. Zur
  Klärung vorgelegt.)*

- **war AK-12** · Angenommen, die Spalte „% of Total" wird angeklickt, wenn sortiert
  werden soll, dann **passiert nichts** — sie ist als einzige nicht sortierbar.
  *(`ContentView.swift:252` — `TableColumn("% of Total")` ohne `value:`. Fachlich
  entspricht die Sortierung der nach Größe, aber der Unterschied ist nicht erkennbar.
  Am 2026-08-23 als Fehler eingestuft.)*

- **war AK-13** · Angenommen, sortiert wird, wenn die Reihenfolge angewendet wird, dann
  wird **`engine.groups` verändert** — also der gemeinsame Zustand, den auch die
  Menüleisten-Kurzfassung liest.
  *(`ContentView.swift:265-267` sortiert die Quelle statt der Anzeige. Es funktioniert,
  weil `filteredGroups` daraus abgeleitet wird, vermischt aber Darstellung und
  Zustand. Am 2026-08-23 als Fehler eingestuft.)*

- **war AK-14** · Angenommen, mehr als acht Endungen liegen vor, wenn die Farbbalken
  gezeichnet werden, dann sind ab dem neunten Eintrag **alle grau** — die Palette hat
  acht Farben.
  *(`colorForGroup` gibt `.gray` zurück, sobald der Index die Palettenlänge übersteigt.
  In den Diagrammen ist Grau der Sammelposten „Other"; in der Tabelle bedeutet es
  lediglich „keine Farbe mehr übrig". Am 2026-08-23 als Fehler eingestuft.)*

## Offene Fragen

- **OF-01** · ~~Soll die Anteilsspalte sortierbar werden~~
  **Ja, umgesetzt am 2026-08-24.** Die Spalte trägt jetzt `value: \.totalBytes` und ist sortierbar wie die übrigen. Dass sie fachlich der Größensortierung entspricht, ist für den Nutzer nicht erkennbar — eine tote Spaltenüberschrift irritiert mehr, als die Dopplung stört.

## Decision Log

| # | Frage | Entscheidung | Begründung |
|---|---|---|---|
| 1 | `Table` statt `List` | `List` mit eigenen Zeilen | `Table` bringt Spaltenbreiten, Kopfzeilen und Sortierung mit — auf macOS die richtige Wahl |
| 2 | Farbbalken je Zeile | keine Farbe | Verbindet Tabelle und Diagramme optisch. Preis: die Palette reicht nur für acht (AK-14) |
| 3 | Anteil als Balken **und** Zahl | nur eine Darstellung | Der Balken für den schnellen Blick, die Zahl für den Vergleich |
| 4 | Farbe nach Größe, nicht nach Sortierung | Farbe nach Zeilenposition | Eine Endung behält ihre Farbe beim Umsortieren — richtig entschieden |
| — | Sind die ⚠-Kriterien gewolltes Verhalten? | **Nein, 4 davon sind Fehler** (2026-08-23) | Gebündelt entschieden über alle Features hinweg; die Muster stehen in `features/index.md` |
