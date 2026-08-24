# B06 · Duplikatsuche — Spezifikation

Status: `review` · Stand: 2026-08-24 · geprüft, siehe `qa-report.md`

> Beschrieben ist, was der Bestand am 2026-08-23 tut — nicht, was er tun sollte.
> **Alle Kriterien in diesem Dokument beschreiben Verhalten, das so gewollt ist.**
> Was fragwürdig war, wurde am 2026-08-23 entschieden und steht im *Fehlbestand*.

## Zweck

Die App findet Dateien mit identischem Inhalt und zeigt, wie viel Platz frei würde,
wenn von jeder Gruppe eine Kopie bliebe. Sie löscht nichts — jede Fundstelle lässt sich
im Finder öffnen, entschieden wird dort.

Es ist das einzige Feature, das **Dateiinhalte** liest, und damit das rechenintensivste
der Anwendung.

## Abhängigkeiten

| Braucht | Status | Warum |
|---|---|---|
| B01 · Ordner scannen | `rekonstruiert` | Arbeitet auf `engine.scannedURLs`; ohne Scan gibt es nichts zu vergleichen |

## User Stories

- **US-01** · Als Nutzer möchte ich doppelte Dateien finden, um Platz zurückzugewinnen.
- **US-02** · Als Nutzer möchte ich sehen, wie viel Platz konkret frei würde, damit ich
  einschätzen kann, ob sich der Aufwand lohnt.
- **US-03** · Als Nutzer möchte ich jede Fundstelle im Finder öffnen können, damit ich
  selbst entscheide, welche Kopie bleibt.

## Nicht im Scope

- **Löschen, Verschieben, Verknüpfen von Dateien.** Dauerhaftes Nicht-Ziel des ganzen
  Produkts (siehe `docs/prd.md`). Der Code sagt es selbst: „FileScope does not delete
  files."
- **Ähnlichkeitssuche** (visuell ähnliche Bilder, gleiche Musikstücke in anderer
  Kodierung). Verglichen wird ausschließlich der exakte Inhalt.

## Akzeptanzkriterien

### Auslösen

- **AK-01** · Angenommen, ein Ordner ist gescannt, wenn „Find Duplicates" gewählt wird,
  dann öffnet sich ein Blatt und die Suche beginnt.
- **AK-02** · Angenommen, kein Scan liegt vor oder ein Scan läuft, wenn die
  Werkzeugleiste gezeichnet wird, dann ist „Find Duplicates" ausgegraut.
- **AK-03** · Angenommen, das Blatt ist offen, wenn „Done" gewählt wird, dann schließt
  es sich; ein bereits ermitteltes Ergebnis bleibt für erneutes Öffnen erhalten.

### Erkennen

- **AK-04** · Angenommen, Dateien werden verglichen, wenn die Suche läuft, dann erfolgt
  das **zweistufig**: erst Gruppierung nach exakter Dateigröße, dann SHA-256 nur für
  Größen, die mindestens zweimal vorkommen.
- **AK-05** · Angenommen, zwei Dateien haben identischen Inhalt, wenn die Suche läuft,
  dann erscheinen sie in derselben Gruppe.
- **AK-06** · Angenommen, zwei Dateien sind gleich groß, unterscheiden sich aber im
  Inhalt, wenn sie gehasht werden, dann bilden sie **keine** Gruppe.
- **AK-07** · Angenommen, eine Datei ist kleiner als 1 KB, wenn die Suche läuft, dann
  wird sie **nicht** berücksichtigt.
- **AK-08** · Angenommen, eine sehr große Datei wird gehasht, wenn sie gelesen wird,
  dann geschieht das in Blöcken von 1 MB, sodass sie nie vollständig im Speicher liegt.

### Ergebnis

- **AK-09** · Angenommen, Gruppen wurden gefunden, wenn das Blatt sie zeigt, dann sind
  sie absteigend nach verschwendetem Platz sortiert.
- **AK-10** · Angenommen, eine Gruppe enthält *n* Kopien der Größe *g*, wenn der
  verschwendete Platz berechnet wird, dann ergibt sich `g × (n − 1)`.
- **AK-11** · Angenommen, das Ergebnis liegt vor, wenn der Kopf des Blattes gezeichnet
  wird, dann zeigt er die Anzahl der Gruppen und den insgesamt rückgewinnbaren Platz.
- **AK-12** · Angenommen, eine Gruppe wird angezeigt, wenn ihre Kopfzeile erscheint,
  dann nennt sie die Anzahl der Kopien, die Größe einer Kopie und den verschwendeten
  Anteil — letzteren in der Warnfarbe.
- **AK-13** · Angenommen, eine Fundstelle wird angezeigt, wenn die Lupe daneben gewählt
  wird, dann öffnet der Finder den enthaltenden Ordner mit ausgewählter Datei.
- **AK-14** · Angenommen, nichts wurde gefunden, wenn die Suche endet, dann erscheint
  „No duplicate files found" mit einem Häkchen.
- **AK-15** · Angenommen, Ergebnisse liegen vor, wenn die Liste erscheint, dann steht
  darüber der Hinweis, dass FileScope nichts löscht und die Prüfung im Finder erfolgt.

### Zu Fehlern erklärt — nicht mehr als Kriterium geführt

Die Nummern **AK-16, AK-17, AK-18, AK-19, AK-20** beschrieben Verhalten, das der Code tatsächlich zeigt, und
waren als ⚠-Kriterien aufgenommen. Am 2026-08-23 wurden sie als **Fehler** eingestuft und
in den *Fehlbestand* überführt. Die Nummern bleiben unbesetzt, damit Verweise aus
`design.md` und aus späteren Berichten eindeutig bleiben.

**Für `sdd-qa` heißt das:** keine zu bestätigenden Kriterien, sondern eine Suchliste.

## Edge Cases

- **EC-01** · Datei nicht lesbar → `sha256Hash` liefert `nil`, die Datei fällt
  stillschweigend aus der Suche.
- **EC-02** · Datei wird während der Suche gelöscht → dito.
- **EC-03** · Alle Dateien kleiner als 1 KB → „No duplicate files found", ohne Hinweis
  darauf, dass gar nicht gesucht wurde.
- **EC-04** · Symlink und Ziel im selben Bestand → identischer Inhalt beim Lesen, wird
  als Duplikat gemeldet.
- **EC-05** · Drei oder mehr Kopien → eine Gruppe, `wastedBytes` rechnet mit *n − 1*.
- **EC-06** · Blatt wird während der Suche geschlossen → die Suche läuft weiter, das
  Ergebnis erscheint beim nächsten Öffnen.
- **EC-07** · Erneutes Auslösen während einer laufenden Suche → nicht gesperrt; ein
  zweiter Durchlauf startet und überschreibt am Ende das Ergebnis des ersten.

## Fehlbestand

- **FB-B06-01 · Die Fortschrittsanzeige zeigt keinen Fortschritt.** Siehe AK-16. Folge:
  Bei langen Läufen ist nicht erkennbar, ob die App arbeitet.

- **FB-B06-02 · Kein Abbruch.** `detect(urls:)` startet einen `Task`, dessen
  Abbruchzustand nie geprüft wird. Folge: siehe AK-19.

- **FB-B06-03 · Die 1-KB-Schwelle ist nirgends sichtbar.** `DuplicateDetector.swift:55`.
  Weder Oberfläche noch Website noch CHANGELOG erwähnen sie. Folge: „Keine Duplikate
  gefunden" kann bedeuten, dass keine gesucht wurden.

- **FB-B06-04 · Keine Prüfung auf Hardlinks.** Folge: siehe AK-18 — der ausgewiesene
  rückgewinnbare Platz kann deutlich zu hoch sein.

- **FB-B06-05 · Kein vorgeschalteter Teilvergleich.** Folge: siehe AK-20; unnötige
  Lesearbeit bei großen, gleich großen, aber verschiedenen Dateien.

- **FB-B06-06 · Der Löschhinweis fehlt im Leerfall.** `DuplicateResultView.swift:71`
  zeigt „FileScope does not delete files" nur in der Ergebnisliste, nicht bei
  „No duplicate files found". Folge: geringfügig, aber die klarste Zusage des Produkts
  erscheint ausgerechnet dann nicht, wenn nichts gefunden wurde.

- **FB-B06-07 · Kein Schutz gegen gleichzeitige Läufe.** Siehe EC-07.

- **FB-B06-08 · Kein Test.** Die Erkennungslogik ist reine Rechenlogik über Dateien und
  ließe sich mit einem Testordner vollständig prüfen. Es gibt keinen Test.

### Aus Kriterien zu Fehlern erklärt (2026-08-23)

- **war AK-16** · Angenommen, die Suche läuft über viele große Dateien, wenn der Nutzer
  auf das Blatt sieht, dann steht die Fortschrittsleiste die **gesamte Laufzeit auf
  null** und springt am Ende auf voll.
  *(`DuplicateDetector.swift:33,45` — `progress` wird auf `0` gesetzt und erst nach dem
  Ende auf `1.0`; dazwischen berechnet niemand etwas. Die Leiste erweckt den Eindruck
  eines Fortschritts, den es nicht gibt. Am 2026-08-23 als Fehler eingestuft.)*

- **war AK-17** · Angenommen, ein Kategoriefilter ist gesetzt (B03), wenn die Suche
  gestartet wird, dann durchsucht sie **trotzdem alle** gescannten Dateien.
  *(`ContentView.swift:131` übergibt `engine.scannedURLs`, nicht die gefilterte Menge.
  Die Website verspricht, der Filter wirke auf alles. Am 2026-08-23 als Fehler eingestuft.)*

- **war AK-18** · Angenommen, eine Datei existiert als zwei Hardlinks, wenn die Suche
  läuft, dann werden beide als Duplikat gemeldet und ihr Platz als rückgewinnbar
  ausgewiesen — obwohl sie **denselben** Speicher belegen und Löschen nichts freigibt.
  *(Gleiche Größe, gleicher Inhalt, also gleicher Hash. Es gibt keine Prüfung auf
  Dateisystem-Identität. Am 2026-08-23 als Fehler eingestuft.)*

- **war AK-19** · Angenommen, die Suche läuft über einen sehr großen Bestand, wenn der
  Nutzer sie abbrechen möchte, dann **gibt es keine Möglichkeit dazu** — auch das
  Schließen des Blattes hält sie nicht an.
  *(Am 2026-08-23 als Fehler eingestuft.)*

- **war AK-20** · Angenommen, zwei Dateien sind gleich groß und je 10 GB groß, wenn sie
  verglichen werden, dann werden **20 GB vollständig gelesen**, bevor feststeht, ob sie
  sich unterscheiden.
  *(Es gibt keinen vorgeschalteten Teilvergleich der ersten Blöcke, der die meisten
  Nicht-Treffer sofort ausschlösse. Am 2026-08-23 als Fehler eingestuft.)*

## Offene Fragen

- **OF-01** · ~~Soll die 1-KB-Schwelle bleiben, verstellbar werden oder entfallen?~~
  **Bleibt, wird aber sichtbar.** Entschieden am 2026-08-24: Die Schwelle verhindert Massen belangloser Treffer; das Blatt nennt jetzt, wie viele Dateien deshalb nicht verglichen wurden.
- **OF-02** · ~~Soll die Suche dem Kategoriefilter folgen (AK-17)?~~
  **Ja, umgesetzt am 2026-08-24.** Die Suche bekommt `engine.filteredURLs` und folgt damit derselben Kategorie wie Tabelle, Diagramme und Export.

## Decision Log

| # | Frage | Entscheidung | Begründung |
|---|---|---|---|
| 1 | Wie werden Duplikate erkannt? | Größe, dann SHA-256 | Der übliche und richtige Aufbau: Die Größenstufe schließt den Großteil ohne Lesearbeit aus |
| 2 | Welcher Hash? | SHA-256 über CryptoKit | Kollisionen praktisch ausgeschlossen. Ein schnellerer nicht-kryptografischer Hash hätte einen Nachvergleich verlangt |
| 3 | Wie wird gelesen? | 1-MB-Blöcke, `autoreleasepool` je Block | Auch Dateien jenseits des Arbeitsspeichers sind verarbeitbar. Sauber gelöst |
| 4 | Dateien unter 1 KB überspringen | Schwelle bei 1024 Bytes | Vermeidet Massen belangloser Treffer. Preis: unsichtbar für den Nutzer (FB-B06-03) |
| 5 | Löschen anbieten? | **Nein** | Dauerhaftes Nicht-Ziel. Der Aufwand für sicheres Löschen mit Rückgängig-Funktion steht in keinem Verhältnis; das kann der Finder |
| — | Sind die ⚠-Kriterien gewolltes Verhalten? | **Nein, 5 davon sind Fehler** (2026-08-23) | Gebündelt entschieden über alle Features hinweg; die Muster stehen in `features/index.md` |
