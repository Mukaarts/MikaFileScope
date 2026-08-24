# B04 · Diagramme — Spezifikation

Status: `review` · Stand: 2026-08-24 · geprüft, siehe `qa-report.md`

> Beschrieben ist, was der Bestand am 2026-08-23 tut — nicht, was er tun sollte.
> **Alle Kriterien in diesem Dokument beschreiben Verhalten, das so gewollt ist.**
> Was fragwürdig war, wurde am 2026-08-23 entschieden und steht im *Fehlbestand*.

## Zweck

Der Reiter *Charts* zeigt dieselben Daten wie die Tabelle in zwei Bildern: einen
Ringdiagramm-Anteil nach Größe und ein waagerechtes Balkendiagramm der größten Typen.
Beide beschränken sich auf die acht größten Endungen und fassen den Rest zusammen.

## Abhängigkeiten

| Braucht | Status | Warum |
|---|---|---|
| B01 · Ordner scannen | `rekonstruiert` | liefert die Gruppen |

## User Stories

- **US-01** · Als Nutzer möchte ich auf einen Blick sehen, welcher Dateityp den Ordner
  dominiert, ohne Zahlen zu vergleichen.
- **US-02** · Als Nutzer möchte ich die größten Typen der Größe nach nebeneinander
  sehen.

## Nicht im Scope

- **Anteile nach Anzahl** — beide Diagramme zeigen ausschließlich Volumen.
- **Auswahl oder Detailanzeige** durch Anklicken eines Segments.
- **Zeitliche Entwicklung** — B05.

## Akzeptanzkriterien

- **AK-01** · Angenommen, ein Scan liegt vor, wenn der Reiter *Charts* gewählt wird,
  dann erscheinen untereinander „Distribution by Size" als Ringdiagramm mit Legende und
  „Top File Types by Size" als waagerechtes Balkendiagramm.
- **AK-02** · Angenommen, die Diagrammdaten werden gebildet, wenn sortiert wird, dann
  absteigend nach Gesamtgröße.
- **AK-03** · Angenommen, mehr als acht Endungen liegen vor, wenn die Daten gebildet
  werden, dann erscheinen die acht größten einzeln und alle übrigen als ein grauer
  Sammelposten „Other", dessen Größe und Anzahl aufsummiert sind.
- **AK-04** · Angenommen, höchstens acht Endungen liegen vor, wenn die Daten gebildet
  werden, dann entsteht **kein** Sammelposten.
- **AK-05** · Angenommen, das Ringdiagramm wird gezeichnet, wenn seine Form entsteht,
  dann hat es einen Innenradius von 50 %, 1,5 Punkt Abstand zwischen den Segmenten und
  abgerundete Ecken.
- **AK-06** · Angenommen, die Legende wird gezeichnet, wenn ein Eintrag erscheint, dann
  zeigt sie einen farbigen Punkt, die Endung und rechtsbündig die lesbare Größe.
- **AK-07** · Angenommen, das Balkendiagramm wird gezeichnet, wenn die waagerechte Achse
  beschriftet wird, dann stehen dort lesbare Größen statt reiner Byte-Zahlen.
- **AK-08** · Angenommen, die Balkenzahl ändert sich, wenn die Höhe bestimmt wird, dann
  wächst sie mit 36 Punkt je Balken zuzüglich 20 Punkt.
- **AK-09** · Angenommen, ein neues Scanergebnis liegt vor, wenn die Diagramme sich
  ändern, dann geschieht das mit einer weichen Federbewegung.
- **AK-10** · Angenommen, ein Kategoriefilter ist gesetzt, wenn die Diagramme gezeichnet
  werden, dann zeigen sie **nur** die gefilterten Gruppen.

### Zu Fehlern erklärt — nicht mehr als Kriterium geführt

Die Nummern **AK-11, AK-12, AK-13, AK-14** beschrieben Verhalten, das der Code tatsächlich zeigt, und
waren als ⚠-Kriterien aufgenommen. Am 2026-08-23 wurden sie als **Fehler** eingestuft und
in den *Fehlbestand* überführt. Die Nummern bleiben unbesetzt, damit Verweise aus
`design.md` und aus späteren Berichten eindeutig bleiben.

**Für `sdd-qa` heißt das:** keine zu bestätigenden Kriterien, sondern eine Suchliste.

## Edge Cases

- **EC-01** · Genau acht Endungen → kein Sammelposten (AK-04).
- **EC-02** · Eine einzige Endung → ein voller Ring, ein Balken.
- **EC-03** · Alle Gruppen 0 Byte → alle Segmente 0; das Ringdiagramm bleibt leer.
- **EC-04** · Sehr lange Endung → in der Legende auf eine Zeile begrenzt und gekürzt.
- **EC-05** · Kategoriefilter lässt nichts übrig → der Reiter wird gar nicht erst
  gezeichnet, `noMatchState` erscheint stattdessen.

## Fehlbestand

- **FB-B04-01 · `chartData` wird je Neuzeichnen mehrfach berechnet.** Siehe AK-11.
  Folge: dreifacher Aufwand ohne Nutzen; ein zwischengespeicherter Wert genügte.

- **FB-B04-02 · Keine Interaktion in den Diagrammen.** Siehe AK-12. Folge: Bei acht
  ähnlichen Grüntönen ist die Zuordnung über die Legende mühsam.

- **FB-B04-03 · Grau bedeutet zweierlei.** Siehe AK-13.

- **FB-B04-04 · `ChartItem` trägt eine Farbe.** Modell und Darstellung sind vermischt
  (DM-06). Folge: Eine zweite Ansicht mit anderer Farbgebung wäre nur durch Kopieren
  möglich.

- **FB-B04-05 · Anteile nur nach Größe, nie nach Anzahl.** `ChartItem.count` wird
  gebildet, aber **nirgends angezeigt** — totes Feld. Folge: Die naheliegende zweite
  Sicht ist halb vorbereitet und ungenutzt.

- **FB-B04-06 · Keine Barrierefreiheitsangaben.** Die Diagramme tragen keine
  beschreibenden Beschriftungen; für Bedienungshilfen bleibt nur die Legende.

- **FB-B04-07 · Die Palette ist nicht farbfehlsichtigkeitssicher.** Acht Farbtöne in
  gleichmäßigem 45°-Abstand bei fester Sättigung und Helligkeit (DS-08); bei Rot-Grün-
  Schwäche fallen mehrere zusammen.

### Aus Kriterien zu Fehlern erklärt (2026-08-23)

- **war AK-11** · Angenommen, der Reiter *Charts* wird gezeichnet, wenn die Diagrammdaten
  gebraucht werden, dann werden sie **dreimal neu berechnet** — je einmal für den Ring,
  die Legende und die Balken.
  *(`chartData` ist eine berechnete Eigenschaft; jeder Zugriff sortiert die Gruppen neu
  und baut die Liste erneut auf. Am 2026-08-23 als Fehler eingestuft.)*

- **war AK-12** · Angenommen, ein Segment des Ringdiagramms wird angeklickt, wenn der
  Nutzer Genaueres erfahren will, dann **passiert nichts** — es gibt weder Kurzinfo noch
  Auswahl noch Beschriftung im Diagramm selbst.
  *(Die Zuordnung Farbe → Endung ist nur über die Legende möglich. Zur Klärung
  vorgelegt.)*

- **war AK-13** · Angenommen, der Sammelposten „Other" erscheint, wenn er eingefärbt wird,
  dann ist er **grau** — dieselbe Farbe, die in der Tabelle jede Endung ab Rang neun
  bekommt.
  *(Siehe AK-14 in B02. Dieselbe Farbe bedeutet an zwei Stellen Verschiedenes. Zur
  Klärung vorgelegt.)*

- **war AK-14** · Angenommen, `ChartItem` wird gebildet, wenn seine Kennung entsteht, dann
  ist es die Endung — zwei Gruppen mit derselben Endung ergäben dieselbe Kennung.
  *(Kann heute nicht auftreten, weil B01 nach Endung gruppiert; die Annahme ist aber
  nirgends abgesichert. Am 2026-08-23 als Fehler eingestuft.)*

## Offene Fragen

- **OF-01** · ~~Soll eine Ansicht nach Dateianzahl ergänzt werden? Das Feld dafür existiert bereits (FB-B04-05).~~
  **Nein, verworfen am 2026-08-24.** `ChartItem.count` bleibt ungenutzt. Die Frage des Produkts lautet „wo ist mein Platz hin", nicht „wie viele Dateien" — die Anzahl steht in der Tabelle. Eine zweite Diagrammansicht wäre ein eigenes Feature mit eigener Spec.

## Decision Log

| # | Frage | Entscheidung | Begründung |
|---|---|---|---|
| 1 | Swift Charts statt eigener Zeichnung | Core Graphics, fremde Bibliothek | Systemeigen, adaptiv, ohne Abhängigkeit — die richtige Wahl für macOS 14 |
| 2 | Ring statt Torte | volle Torte | Der Innenraum wirkt ruhiger; auf macOS die gängigere Form |
| 3 | Top 8 plus „Other" | alle Endungen zeigen | Mehr als acht Segmente sind nicht mehr unterscheidbar. Die Zahl entspricht der Palettengröße |
| 4 | Anteile nach Größe, nicht nach Anzahl | beides zeigen | Die Frage lautet „wo ist mein Platz hin", nicht „wie viele Dateien". `count` wurde trotzdem mitgeführt (FB-B04-05) |
| 5 | Eigene `ChartItem`-Struktur | direkt `FileTypeGroup` zeichnen | Nötig, um „Other" als Pseudogruppe einzufügen. Preis: die Farbe wandert ins Modell (FB-B04-04) |
| — | Sind die ⚠-Kriterien gewolltes Verhalten? | **Nein, 4 davon sind Fehler** (2026-08-23) | Gebündelt entschieden über alle Features hinweg; die Muster stehen in `features/index.md` |
