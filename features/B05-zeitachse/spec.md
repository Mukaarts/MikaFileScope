# B05 · Zeitachse — Spezifikation

Status: `review` · Stand: 2026-08-24 · geprüft, siehe `qa-report.md`

> Beschrieben ist, was der Bestand am 2026-08-23 tut — nicht, was er tun sollte.
> **Alle Kriterien in diesem Dokument beschreiben Verhalten, das so gewollt ist.**
> Was fragwürdig war, wurde am 2026-08-23 entschieden und steht im *Fehlbestand*.

## Zweck

Der Reiter *Timeline* zeigt, wie alt der Inhalt eines Ordners ist: zwei Balkendiagramme
über sieben Zeitfenster — eines nach Dateianzahl, eines nach Volumen. Es beantwortet die
Frage, ob ein Ordner lebt oder nur liegt.

## Abhängigkeiten

| Braucht | Status | Warum |
|---|---|---|
| B01 · Ordner scannen | `rekonstruiert` | die Zeitfenster entstehen bereits während des Scans |

## User Stories

- **US-01** · Als Nutzer möchte ich sehen, wie viel eines Ordners aus dem letzten Jahr
  stammt und wie viel älter ist.
- **US-02** · Als Nutzer möchte ich Anzahl und Volumen getrennt sehen — viele kleine
  neue Dateien sind etwas anderes als ein altes großes Archiv.

## Nicht im Scope

- **Filtern nach Zeitraum** — die Zeitachse zeigt nur, sie schränkt nicht ein.
- **Anzeige einzelner Dateien** eines Zeitfensters.
- **Erstellungsdatum** — gemessen wird ausschließlich das Änderungsdatum.

## Akzeptanzkriterien

- **AK-01** · Angenommen, ein Scan liegt vor, wenn der Reiter *Timeline* gewählt wird,
  dann erscheint die Überschrift „File Age Distribution" und darunter zwei Diagramme.
- **AK-02** · Angenommen, die Diagramme erscheinen, wenn sie beschriftet werden, dann
  heißen sie „File Count by Age" und „Total Size by Age".
- **AK-03** · Angenommen, Dateien werden einsortiert, wenn ihr Zeitfenster bestimmt
  wird, dann geschieht das nach **ganzen Tagen** Abstand zwischen Änderungsdatum und
  Jetzt: 0 → *Today*, 1–7 → *Past Week*, 8–30 → *Past Month*, 31–90 → *Past 3 Months*,
  91–365 → *Past Year*, darüber → *Older*.
- **AK-04** · Angenommen, die Balken erscheinen, wenn sie angeordnet werden, dann stehen
  sie chronologisch — vom jüngsten zum ältesten Fenster.
- **AK-05** · Angenommen, ein Balken wird eingefärbt, wenn seine Farbe bestimmt wird,
  dann ist er umso kräftiger, je jünger das Fenster ist, und verläuft zu blassem Grau
  für die ältesten.
- **AK-06** · Angenommen, das Größendiagramm wird gezeichnet, wenn die senkrechte Achse
  beschriftet wird, dann stehen dort lesbare Größen, keine reinen Byte-Zahlen.
- **AK-07** · Angenommen, keine Datei trug ein Änderungsdatum, wenn der Reiter geöffnet
  wird, dann erscheint „No date information available".
- **AK-08** · Angenommen, eine Datei trägt kein Änderungsdatum, wenn sie gescannt wird,
  dann zählt sie in der Endungsstatistik mit, **fehlt** aber in der Zeitachse.

- **AK-09** · Angenommen, ein Kategoriefilter ist gesetzt, wenn die Zeitachse
  gezeichnet wird, dann zeigt sie **den gesamten Ordner** — der Filter wirkt hier
  bewusst nicht. *(Am 2026-08-23 als dokumentierte Ausnahme bestätigt: Die Zeitfenster
  werden bereits während des Scans verdichtet, ohne die Endung mitzuführen. Eine
  Filterung wäre nur über eine Änderung am Datenmodell und an B01 möglich. Der
  Unterschied zu B06 und B08 ist wesentlich — dort war es ein Versehen, hier eine
  Folge des Entwurfs.)*

### Zu Fehlern erklärt — nicht mehr als Kriterium geführt

Die Nummern **AK-10, AK-11, AK-12** beschrieben Verhalten, das der Code tatsächlich zeigt, und
waren als ⚠-Kriterien aufgenommen. Am 2026-08-23 wurden sie als **Fehler** eingestuft und
in den *Fehlbestand* überführt. Die Nummern bleiben unbesetzt, damit Verweise aus
`design.md` und aus späteren Berichten eindeutig bleiben.

**Für `sdd-qa` heißt das:** keine zu bestätigenden Kriterien, sondern eine Suchliste.

## Edge Cases

- **EC-01** · Alle Dateien am selben Tag geändert → ein einziger Balken.
- **EC-02** · Ordner mit nur alten Dateien → nur *Older*, ein Balken über die volle
  Breite.
- **EC-03** · Änderungsdatum liegt vor 1970 → sehr großer Tagesabstand, landet in
  *Older*.
- **EC-04** · Kein Scan → der Reiter ist nicht erreichbar (Leerzustand).

## Fehlbestand

- **FB-B05-01 · Die Zeitachse folgt dem Kategoriefilter nicht — und kann es nicht.**
  Siehe AK-09. Folge: Um das zu ändern, müsste `ScanEngine` die Endung je Zeitfenster
  mitführen oder die Zeitfenster aus `scannedURLs` nachträglich bilden. Es ist der
  einzige Filterbefund, der einen Eingriff ins Datenmodell verlangt.

- **FB-B05-02 · Das Fenster `Future` ist undokumentiert.** Siehe AK-10 und DM-05.

- **FB-B05-03 · Bezugszeitpunkt wird je Datei neu bestimmt.** Siehe AK-11. Folge:
  theoretisch inkonsistente Einordnung; praktisch nur bei sehr langen Scans relevant.

- **FB-B05-04 · Leere Zeitfenster fehlen.** Siehe AK-12.

- **FB-B05-05 · Der Farbverlauf umgeht das Farbsystem.** `HistogramView.swift:83-89`
  bildet seine Farben aus den Zahlen `148`, `0.70` und `0.75` — denselben Werten wie in
  `MikaPlusColors`, aber ein zweites Mal fest im Code (DS-03).

- **FB-B05-06 · Keine Achsenbeschriftung im Anzahldiagramm.** Nur die Fensternamen
  stehen an der waagerechten Achse; die senkrechte Achse bleibt ohne Einheit.

- **FB-B05-07 · `dateBucketKey(for:)` liegt in `ScanEngine`, gehört aber fachlich
  hierher.** Kein Fehler, aber der Grund, warum ein Test für dieses Feature den
  Scan-Code berühren müsste.

### Aus Kriterien zu Fehlern erklärt (2026-08-23)

- **war AK-10** · Angenommen, eine Datei trägt ein Änderungsdatum in der Zukunft, wenn sie
  einsortiert wird, dann landet sie im Fenster **`Future`** — das weder im CHANGELOG
  noch auf der Website vorkommt; beide nennen sechs Fenster, der Code kennt sieben.
  *(`ScanEngine.swift:177`. Am 2026-08-23 als Fehler eingestuft.)*

- **war AK-11** · Angenommen, ein Scan dauert lange, wenn Dateien einsortiert werden, dann
  wird der Bezugszeitpunkt „jetzt" **für jede Datei neu** ermittelt.
  *(`dateBucketKey(for:)` ruft `Date()` und `Calendar.current` bei jedem Aufruf. Bei
  einem Scan über Mitternacht können zwei gleich alte Dateien in verschiedenen Fenstern
  landen. Am 2026-08-23 als Fehler eingestuft.)*

- **war AK-12** · Angenommen, ein Fenster enthält keine Datei, wenn die Diagramme
  gezeichnet werden, dann **fehlt es ganz** — statt als leerer Balken zu erscheinen.
  *(Die Fenster entstehen nur, wo Dateien gefunden wurden. Folge: Die Achse zeigt je
  nach Ordner unterschiedlich viele Balken, was den Vergleich zweier Ordner erschwert.
  Am 2026-08-23 als Fehler eingestuft.)*

## Offene Fragen

- **OF-01** · ~~Soll die Zeitachse dem Kategoriefilter folgen? Die Antwort entscheidet über eine Änderung am Datenmodell (FB-B05-01).~~
  **Nein — bewusste Ausnahme, bestätigt am 2026-08-24.** Die Zeitfenster werden während des Scans verdichtet, ohne die Endung mitzuführen; eine Filterung verlangte eine Änderung am Datenmodell und an B01. Die Website nennt die Einschränkung jetzt ausdrücklich.
- **OF-02** · ~~Soll `Future` dokumentiert oder mit *Today* zusammengelegt werden?~~
  **Dokumentiert, nicht zusammengelegt** (2026-08-24). `Future` steht in `docs/datenmodell.md` und wird von `DateBucketTests.test_zukunftsdatum` geprüft. Ein Datum in der Zukunft ist ein Hinweis auf eine falsch gestellte Uhr — es unter „Today" zu verstecken verschleierte das.

## Decision Log

| # | Frage | Entscheidung | Begründung |
|---|---|---|---|
| 1 | Feste Fenster statt gleichmäßiger Achse | echte Zeitachse mit Datum | Feste Fenster sind ohne Vorwissen lesbar; „Past Week" sagt mehr als ein Datumsbereich |
| 2 | Zeitfenster bereits beim Scan bilden | Datum je Datei behalten und später verdichten | Spart Speicher — und macht die Filterung unmöglich (FB-B05-01). Der Zusammenhang war beim Bauen vermutlich nicht absehbar |
| 3 | Änderungsdatum statt Erstellungsdatum | `creationDateKey` | Das Änderungsdatum beantwortet die eigentliche Frage: Wird die Datei noch benutzt? |
| 4 | Zwei getrennte Diagramme | eines mit zwei Achsen | Anzahl und Volumen unterscheiden sich um Größenordnungen; gemeinsam wäre eines unlesbar |
| — | Sind die ⚠-Kriterien gewolltes Verhalten? | **Nein, 3 davon sind Fehler** (2026-08-23) | Gebündelt entschieden über alle Features hinweg; die Muster stehen in `features/index.md` |
