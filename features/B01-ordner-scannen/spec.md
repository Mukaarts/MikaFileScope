# B01 · Ordner scannen — Spezifikation

Status: `review` · Stand: 2026-08-24 · geprüft, siehe `qa-report.md`

> Beschrieben ist, was der Bestand am 2026-08-23 tut — nicht, was er tun sollte.
> **Alle Kriterien in diesem Dokument beschreiben Verhalten, das so gewollt ist.**
> Was fragwürdig war, wurde am 2026-08-23 entschieden und steht im *Fehlbestand*.

## Zweck

Der Nutzer wählt einen Ordner, die App durchläuft ihn rekursiv und sammelt für jede
Datei Endung, Größe und Änderungsdatum. Alle übrigen Features leben von diesem
Ergebnis — B01 ist die Datenquelle der ganzen Anwendung.

## Abhängigkeiten

Keine. B01 ist die Wurzel des Abhängigkeitsbaums.

## User Stories

- **US-01** · Als Nutzer möchte ich einen Ordner per Dialog oder Drag-and-drop wählen,
  damit ich ohne Umwege loslegen kann.
- **US-02** · Als Nutzer möchte ich, dass die App während des Scans bedienbar bleibt,
  damit große Ordner das Fenster nicht einfrieren.
- **US-03** · Als Nutzer möchte ich versteckte Dateien ein- und ausschließen können,
  damit ich sehe, was mich interessiert.
- **US-04** · Als Nutzer möchte ich denselben Ordner erneut scannen können, um
  Änderungen zu sehen.

## Nicht im Scope

- **Darstellung der Ergebnisse** — B02 (Tabelle), B04 (Diagramme), B05 (Zeitachse).
- **Filtern nach Kategorie** — B03. B01 liefert immer den vollständigen Bestand.
- **Lesen von Dateiinhalten** — nur B06 tut das.

## Akzeptanzkriterien

### Ordner wählen

- **AK-01** · Angenommen, die App ist offen, wenn „Choose Folder" gewählt wird, dann
  erscheint ein Systemdialog mit dem Hinweis „Choose a folder to scan", in dem **nur
  Ordner** und **nur einer** auswählbar sind.
- **AK-02** · Angenommen, der Dialog wird abgebrochen, wenn er sich schließt, dann
  passiert nichts — kein Scan, keine Änderung am Zustand.
- **AK-03** · Angenommen, ein Ordner wird auf das Fenster gezogen, wenn er losgelassen
  wird, dann startet der Scan dieses Ordners.
- **AK-04** · Angenommen, noch kein Ordner wurde gescannt und ein Objekt schwebt über
  dem Fenster, wenn es über dem Ablagebereich ist, dann färben sich Symbol und
  gestrichelter Rahmen in der Markenfarbe.
- **AK-05** · Angenommen, kein Ordner ist gewählt, wenn die App startet, dann zeigt sie
  „Drop a folder here or click Choose Folder" mit einer Schaltfläche.

### Scannen

- **AK-06** · Angenommen, ein Ordner ist gewählt, wenn der Scan läuft, dann erscheint in
  der Werkzeugleiste eine Fortschrittsanzeige und das Fenster bleibt bedienbar.
- **AK-07** · Angenommen, ein Ordner enthält Unterordner, wenn er gescannt wird, dann
  werden **alle Ebenen** durchlaufen, nicht nur die oberste.
- **AK-08** · Angenommen, der Scan läuft, wenn Verzeichnisse angetroffen werden, dann
  zählen sie **nicht** als Datei — nur echte Dateien werden erfasst.
- **AK-09** · Angenommen, eine Datei hat keine Endung, wenn sie erfasst wird, dann wird
  sie unter der Bezeichnung `(no extension)` geführt.
- **AK-10** · Angenommen, Dateien haben Endungen in unterschiedlicher Schreibweise
  (`.PNG`, `.png`), wenn sie gruppiert werden, dann landen sie in **derselben** Gruppe.
- **AK-11** · Angenommen, der Scan ist fertig, wenn das Ergebnis übernommen wird, dann
  sind die Gruppen absteigend nach **Anzahl** sortiert.
- **AK-12** · Angenommen, der Scan ist fertig, wenn die Kennzahlenleiste erscheint, dann
  zeigt sie Gesamtzahl der Dateien, Gesamtgröße und Anzahl verschiedener Endungen.

### Versteckte Dateien

- **AK-13** · Angenommen, der Schalter „Hidden Files" ist aus, wenn gescannt wird, dann
  werden Dateien und Ordner, die mit einem Punkt beginnen, übersprungen.
- **AK-14** · Angenommen, ein Ordner ist bereits gescannt, wenn der Schalter umgelegt
  wird, dann startet **sofort** ein neuer Scan desselben Ordners.

### Erneut scannen

- **AK-15** · Angenommen, ein Ordner wurde gescannt, wenn „Rescan" gewählt wird, dann
  wird derselbe Ordner erneut durchlaufen.
- **AK-16** · Angenommen, kein Ordner wurde gescannt oder ein Scan läuft, wenn die
  Werkzeugleiste gezeichnet wird, dann ist „Rescan" ausgegraut.

### Fehler

- **AK-17** · Angenommen, ein Ordner ist nicht lesbar, wenn der Scan startet, dann
  erscheint ein Hinweis „Scan Error" mit dem Text `Cannot access folder: <Pfad>` und
  einer Schaltfläche „OK".
- **AK-18** · Angenommen, der Fehlerhinweis wird bestätigt, wenn er sich schließt, dann
  ist die Meldung zurückgesetzt und erscheint nicht erneut.

### Zu Fehlern erklärt — nicht mehr als Kriterium geführt

Die Nummern **AK-19, AK-20, AK-21, AK-22, AK-23** beschrieben Verhalten, das der Code tatsächlich zeigt, und
waren als ⚠-Kriterien aufgenommen. Am 2026-08-23 wurden sie als **Fehler** eingestuft und
in den *Fehlbestand* überführt. Die Nummern bleiben unbesetzt, damit Verweise aus
`design.md` und aus späteren Berichten eindeutig bleiben.

**Für `sdd-qa` heißt das:** keine zu bestätigenden Kriterien, sondern eine Suchliste.

## Edge Cases

- **EC-01** · Leerer Ordner → Scan endet, Kennzahlen stehen auf 0, die Tabelle ist leer.
- **EC-02** · Datei ohne lesbare Größe → zählt mit **0 Bytes** (`fileSize ?? 0`), die
  Dateianzahl stimmt, die Summe ist zu niedrig.
- **EC-03** · Datei ohne Änderungsdatum → fließt in die Endungsstatistik ein, **fehlt**
  aber in der Zeitachse (B05).
- **EC-04** · Datei mit Änderungsdatum in der Zukunft → landet im Zeitfenster `Future`,
  das die Dokumentation nicht kennt (siehe `docs/datenmodell.md`, DM-05).
- **EC-05** · Ordner wird während des Scans verschoben oder gelöscht → einzelne Lesefehler
  werden verschluckt (AK-20), das Ergebnis ist unvollständig ohne Hinweis.
- **EC-06** · Netzlaufwerk oder Time-Machine-Volume → funktioniert, kann aber sehr lange
  dauern; ohne Abbruch (AK-22) und ohne Fortschritt.
- **EC-07** · Hardlinks → jeder Pfad zählt einzeln, der belegte Speicher wird überschätzt.
- **EC-08** · Eine Datei statt eines Ordners wird abgelegt → wird stillschweigend
  verworfen, obwohl die Ablage als angenommen gilt (`handleDrop` liefert `true`).

## Fehlbestand

- **FB-B01-01 · `startAccessingSecurityScopedResource()` ist wirkungslos.**
  `ScanEngine.swift:94-97`. Ohne Sandbox und ohne zuvor erzeugtes Security-Scoped
  Bookmark tut der Aufruf nichts. Folge: Er sieht nach einer Absicherung aus, die nicht
  existiert. Mit Feature `01` wird er zur Notwendigkeit.

- **FB-B01-02 · Kein Fortschritt während des Scans.** Nur ein unbestimmter Spinner.
  Folge: Bei großen Ordnern ist nicht unterscheidbar, ob die App arbeitet oder hängt.

- **FB-B01-03 · Kein Abbruch.** Weder Scan noch der auslösende `Task.detached` sind
  abbrechbar; `Task.isCancelled` wird nirgends abgefragt. Folge: siehe AK-22.

- **FB-B01-04 · Keine Absicherung gegen gleichzeitige Scans.** Folge: siehe AK-21.

- **FB-B01-05 · `scannedURLs` wächst unbegrenzt.** Jede gefundene Datei wird als `URL`
  behalten, damit B06 sie hashen kann. Folge: bei sehr großen Beständen unbestimmter
  Speicherbedarf; keine Obergrenze, keine Warnung.

- **FB-B01-06 · `reset()` ist toter Code.** `ScanEngine.swift:82-91` wird nirgends
  aufgerufen. Folge: Es gibt keinen Weg zurück in den Leerzustand.

- **FB-B01-07 · Der zuletzt gescannte Ordner wird nicht gemerkt.** Folge: „Rescan"
  überlebt keinen Neustart.

- **FB-B01-08 · Logische statt belegter Größe.** Gemessen wird `fileSizeKey`, nicht
  `totalFileAllocatedSizeKey`. Folge: Bei vielen kleinen Dateien weicht die Summe von
  der Anzeige des Finders ab; komprimierte APFS-Dateien werden überschätzt.

- **FB-B01-09 · Kein Test.** Weder für `dateBucketKey`, das reine Rechenlogik ist und
  sich mühelos prüfen ließe, noch für die Gruppierung.

### Aus Kriterien zu Fehlern erklärt (2026-08-23)

- **war AK-19** · Angenommen, der gescannte Ordner enthält ein Programm oder ein anderes
  Paket (`.app`, `.rtfd`, `.photoslibrary`), wenn gescannt wird, dann wird **jede Datei
  im Paketinneren einzeln gezählt**.
  *(Verifiziert am 2026-08-23 mit einem Testordner und exakt den Optionen aus
  `performScan`: Ein `Beispiel.app` erschien als `Contents/MacOS/binary`. Der Finder
  zeigt ein Paket als **ein** Objekt; wer seinen Programme-Ordner scannt, sieht
  stattdessen zehntausende Einzeldateien. Am 2026-08-23 als Fehler eingestuft.)*

- **war AK-20** · Angenommen, eine einzelne Datei kann nicht gelesen werden, wenn der Scan
  darüber läuft, dann wird sie **stillschweigend übersprungen** und fehlt im Ergebnis,
  ohne dass es irgendwo vermerkt wird.
  *(`ScanEngine.swift:149-151` — `catch { continue }`. Der Fehlerhinweis aus AK-17
  greift nur, wenn der Enumerator gar nicht erst erzeugt werden kann. Folge: Summen
  können zu niedrig sein, und niemand erfährt davon. Am 2026-08-23 als Fehler eingestuft.)*

- **war AK-21** · Angenommen, ein Scan läuft, wenn der Schalter „Hidden Files" umgelegt
  oder ein Ordner abgelegt wird, dann startet ein **zweiter Scan parallel** — beide
  schreiben nach Abschluss in denselben Zustand.
  *(Der Schalter und die Ablagefläche sind während `isScanning` nicht gesperrt, nur
  „Rescan" ist es. Welches Ergebnis am Ende stehen bleibt, hängt davon ab, welcher Lauf
  später fertig wird. Am 2026-08-23 als Fehler eingestuft.)*

- **war AK-22** · Angenommen, ein Scan läuft über einen sehr großen Ordner, wenn der
  Nutzer ihn abbrechen möchte, dann **gibt es keine Möglichkeit dazu** — außer die App
  zu beenden.
  *(Am 2026-08-23 als Fehler eingestuft.)*

- **war AK-23** · Angenommen, ein Symlink liegt im Ordner, wenn gescannt wird, dann wird
  er als **eigene Datei gezählt** — zusätzlich zu seinem Ziel, falls dieses ebenfalls im
  gescannten Bereich liegt.
  *(Verifiziert am 2026-08-23. Der Enumerator listet Verweise auf, folgt ihnen aber
  nicht in die Tiefe. Folge: Der Inhalt kann doppelt in der Statistik auftauchen. Zur
  Klärung vorgelegt.)*

## Offene Fragen

- **OF-01** · ~~Sollen Pakete wie `.app` als **ein** Objekt gezählt werden?~~
  **Ja, entschieden und umgesetzt am 2026-08-24.** `.skipsPackageDescendants` ist gesetzt; ein Programm im gescannten Ordner zählt als ein Objekt, wie im Finder. Belegt: Der Testordner meldet 17 statt 20 Dateien.

## Decision Log

| # | Frage | Entscheidung | Begründung |
|---|---|---|---|
| 1 | Wo läuft der Scan? | `Task.detached` auf eine `nonisolated static` Funktion | Hält den Main Actor frei; Ergebnis kommt als `Sendable`-Struktur zurück. Sauber gelöst und Swift-6-konform |
| 2 | Gruppierung wonach? | Endung, kleingeschrieben | Einfach und verständlich. Preis: Zuordnung rein nach Namen, nie nach Inhalt |
| 3 | Sortierung des Ergebnisses | absteigend nach Anzahl | Die Tabelle sortiert später selbst um; dies ist nur die Voreinstellung |
| 4 | Verhalten bei Lesefehlern | überspringen | **Grund nicht erkennbar.** Robust gegenüber Berechtigungsfehlern, aber ohne jede Rückmeldung (AK-20) |
| — | Sind die ⚠-Kriterien gewolltes Verhalten? | **Nein, 5 davon sind Fehler** (2026-08-23) | Gebündelt entschieden über alle Features hinweg; die Muster stehen in `features/index.md` |
