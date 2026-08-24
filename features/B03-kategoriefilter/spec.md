# B03 · Kategoriefilter — Spezifikation

Status: `review` · Stand: 2026-08-24 · geprüft, siehe `qa-report.md`

> Beschrieben ist, was der Bestand am 2026-08-23 tut — nicht, was er tun sollte.
> **Alle Kriterien in diesem Dokument beschreiben Verhalten, das so gewollt ist.**
> Was fragwürdig war, wurde am 2026-08-23 entschieden und steht im *Fehlbestand*.

## Zweck

Eine Chip-Leiste über der Ansicht schränkt das Ergebnis auf eine von sieben semantischen
Gruppen ein — Bilder, Dokumente, Videos, Audio, Code, Archive, Sonstiges — oder zeigt
alles. Der Filter ist der einzige Bestandteil der App, der in mehrere andere Features
hineinwirkt, und deshalb vor ihnen zu erfassen.

## Abhängigkeiten

| Braucht | Status | Warum |
|---|---|---|
| B01 · Ordner scannen | `rekonstruiert` | filtert dessen Ergebnis |
| B02 · Aufschlüsselung nach Dateityp | `bestand` | die Tabelle ist die Hauptansicht, auf die er wirkt |

## User Stories

- **US-01** · Als Nutzer möchte ich nur meine Bilder betrachten, ohne den Ordner neu zu
  scannen.
- **US-02** · Als Nutzer möchte ich sehen, dass gerade gefiltert wird, damit ich die
  Zahlen richtig deute.

## Nicht im Scope

- **Mehrfachauswahl** von Kategorien.
- **Eigene Kategorien** oder Bearbeiten der Endungslisten.
- **Filtern nach Größe, Alter oder Name.**

## Akzeptanzkriterien

- **AK-01** · Angenommen, ein Scan liegt vor, wenn die Ansicht erscheint, dann steht
  über dem Inhalt eine waagerecht scrollbare Leiste mit acht Chips: All, Images,
  Documents, Videos, Audio, Code, Archives, Other — jeder mit Symbol und Namen.
- **AK-02** · Angenommen, ein Chip wird gewählt, wenn er aktiv wird, dann erhält er
  einen Hintergrund in der Markenfarbe mit 20 % Deckkraft und Schrift in der
  Markenfarbe; alle übrigen bleiben grau.
- **AK-03** · Angenommen, eine Kategorie ist gewählt, wenn die Tabelle gezeichnet wird,
  dann enthält sie **nur** Endungen dieser Kategorie.
- **AK-04** · Angenommen, eine Kategorie ist gewählt, wenn die Kennzahlenleiste
  gezeichnet wird, dann beziehen sich Dateianzahl, Gesamtgröße und Typenzahl **auf die
  gefilterte Menge**.
- **AK-05** · Angenommen, eine Kategorie ist gewählt, wenn die Diagramme gezeichnet
  werden, dann zeigen sie nur die gefilterten Gruppen.
- **AK-06** · Angenommen, eine Kategorie ist gewählt, wenn exportiert wird, dann enthält
  die Datei nur die gefilterten Gruppen.
- **AK-07** · Angenommen, „All" ist gewählt, wenn gefiltert wird, dann wird die
  ungefilterte Menge unverändert durchgereicht.
- **AK-08** · Angenommen, „Other" ist gewählt, wenn gefiltert wird, dann erscheinen genau
  die Endungen, die in **keiner** der sechs benannten Kategorien vorkommen.
- **AK-09** · Angenommen, keine Datei passt zur gewählten Kategorie, wenn die Ansicht
  gezeichnet wird, dann erscheint „No files match this category" anstelle des Inhalts —
  Kennzahlen, Chip-Leiste und Tab-Umschalter bleiben sichtbar.
- **AK-10** · Angenommen, eine Datei trägt die Endung `.PNG`, wenn die Zuordnung
  geschieht, dann greift sie unabhängig von der Groß- und Kleinschreibung.

### Zu Fehlern erklärt — nicht mehr als Kriterium geführt

Die Nummern **AK-11, AK-12, AK-13, AK-14, AK-15** beschrieben Verhalten, das der Code tatsächlich zeigt, und
waren als ⚠-Kriterien aufgenommen. Am 2026-08-23 wurden sie als **Fehler** eingestuft und
in den *Fehlbestand* überführt. Die Nummern bleiben unbesetzt, damit Verweise aus
`design.md` und aus späteren Berichten eindeutig bleiben.

**Für `sdd-qa` heißt das:** keine zu bestätigenden Kriterien, sondern eine Suchliste.

## Edge Cases

- **EC-01** · Kein Scan → die Chip-Leiste erscheint gar nicht erst (Leerzustand).
- **EC-02** · Endung ist leer (`(no extension)`) → gehört zu *Other*, weil sie in keiner
  Menge steht.
- **EC-03** · Endung `.m` → *Code* (Objective-C); MATLAB-Dateien teilen die Endung.
- **EC-04** · Filter wird gewechselt, während ein Scan läuft → erlaubt; die gefilterte
  Sicht bezieht sich auf das noch stehende alte Ergebnis.

## Fehlbestand

- **FB-B03-01 · Der Filter wirkt nur auf drei von fünf Ansichten.** Siehe AK-11 bis
  AK-13. Folge: Dieselbe Größe erscheint gleichzeitig in zwei verschiedenen Zahlen; die
  Website verspricht durchgehende Wirkung.

- **FB-B03-02 · `FileCategory.other` rechnet bei jedem Aufruf neu.**
  `FileCategory.swift:48-52` bildet die Vereinigung aller 106 Endungen pro Aufruf — also
  je Tabellenzeile und je Neuzeichnen. Folge: unnötige Last; gehört einmalig statisch
  berechnet (DM-04).

- **FB-B03-03 · Doppelte Endung `ts` in zwei Kategorien.** Siehe AK-15. Folge: Die Summe
  aller Kategorien kann größer sein als der Gesamtbestand.

- **FB-B03-04 · Der Filter überlebt den Ordnerwechsel.** Siehe AK-14.

- **FB-B03-05 · Die Auswahl wird nicht gespeichert.** Nach einem Neustart steht wieder
  „All". Folge: gering, aber inkonsistent zum Schalter „Hidden Files", der ebenfalls
  nicht gespeichert wird — und zum Menüleisten-Schalter, der es wird.

- **FB-B03-06 · Zuordnung allein über die Endung.** Der Inhalt wird nie geprüft. Eine in
  `.png` umbenannte ZIP-Datei zählt als Bild. Folge: für ein Statistikwerkzeug
  vertretbar, aber nirgends erwähnt.

- **FB-B03-07 · Kein Test.** `matches(ext:)` ist reine Rechenlogik ohne
  Systemabhängigkeit und wäre in wenigen Zeilen vollständig prüfbar.

### Aus Kriterien zu Fehlern erklärt (2026-08-23)

- **war AK-11** · Angenommen, eine Kategorie ist gewählt, wenn der Reiter *Timeline*
  geöffnet wird, dann zeigt die Zeitachse **den gesamten Bestand** — der Filter wirkt
  dort nicht.
  *(`ContentView.swift:223` übergibt `engine.dateBuckets`, die nicht gefiltert werden.
  Am 2026-08-23 als Fehler eingestuft.)*

- **war AK-12** · Angenommen, eine Kategorie ist gewählt, wenn die Duplikatsuche gestartet
  wird, dann durchsucht sie **alle** gescannten Dateien.
  *(Siehe AK-17 in B06. Am 2026-08-23 als Fehler eingestuft.)*

- **war AK-13** · Angenommen, eine Kategorie ist gewählt, wenn die Menüleisten-Kurzfassung
  geöffnet wird, dann zeigt sie **ungefilterte** Zahlen — gleichzeitig mit den
  gefilterten im Hauptfenster.
  *(Siehe AS-01 in `docs/app-shell.md`. Am 2026-08-23 als Fehler eingestuft.)*

- **war AK-14** · Angenommen, eine Kategorie ist gewählt und ein anderer Ordner wird
  gescannt, wenn das Ergebnis erscheint, dann **bleibt der Filter gesetzt** — passt
  nichts, sieht der Nutzer „No files match this category" statt seines neuen Scans.
  *(Weder `scan(folder:)` noch `reset()` setzen `selectedCategory` zurück. Zur Klärung
  vorgelegt.)*

- **war AK-15** · Angenommen, eine Datei trägt die Endung `.ts`, wenn sie zugeordnet wird,
  dann erscheint sie sowohl unter *Videos* als auch unter *Code* — je nachdem, welche
  Kategorie gerade gewählt ist.
  *(`ts` steht in beiden Endungsmengen: MPEG Transport Stream und TypeScript. Zur
  Klärung vorgelegt.)*

## Offene Fragen

- **OF-01** · ~~Soll `ts` einer Kategorie fest zugeordnet werden — und welcher?~~
  **Videos, entschieden am 2026-08-24.** MPEG Transport Stream ist der verbreitetere Fall; TypeScript wird über `tsx`, `mts` und `cts` erfasst. Ein Test stellt sicher, dass keine Endung mehr in zwei Kategorien steht.
- **OF-02** · ~~Soll der Filter beim Ordnerwechsel zurückgesetzt werden?~~
  **Ja, umgesetzt am 2026-08-24.** `scan(folder:)` setzt `selectedCategory` auf `.all`. Ein neuer Ordner, der mit „No files match this category" beginnt, ist kein brauchbarer Zustand.

## Decision Log

| # | Frage | Entscheidung | Begründung |
|---|---|---|---|
| 1 | Feste Kategorien oder frei konfigurierbar? | fest, sieben plus „Alle" | Deckt die üblichen Fälle ohne Einstellungsdialog ab |
| 2 | Wie wird zugeordnet? | über feste Endungsmengen | Ohne Dateizugriff, damit sofort und ohne Kosten — der Preis ist FB-B03-06 |
| 3 | Wo liegt die Filterlogik? | als berechnete Eigenschaften in `ScanEngine` | Eine Quelle für alle Ansichten. Dass drei Verbraucher sie trotzdem umgehen, ist der eigentliche Fehler (FB-B03-01) |
| 4 | Darstellung als Chips | Menü, Segmentleiste | Alle Kategorien auf einen Blick, waagerecht scrollbar bei schmalem Fenster |
| — | Sind die ⚠-Kriterien gewolltes Verhalten? | **Nein, 5 davon sind Fehler** (2026-08-23) | Gebündelt entschieden über alle Features hinweg; die Muster stehen in `features/index.md` |
