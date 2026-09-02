# 01 · Mac App Store — Aufgabenplan

Status: `review` · Stand: 2026-09-02 · 32 von 33 erledigt, 1 teilweise

**Im Store liegt 2.1.0** (`id6804743268`, freigegeben am 2026-09-02) — also die Fassung
*vor* Ebene 6. Dort fehlen die Zweckbeschreibungen, und der Export bleibt wirkungslos,
weil `user-selected.read-only` die Powerbox am Öffnen des Speichern-Dialogs hindert.
2.1.1 behebt beides und ist gebaut, aber noch nicht eingereicht.

Ziel: App-Store-fähig **und** alle offenen Befunde aus dem Audit vom 2026-08-24 geschlossen.
Grundlage: `docs/audit-2026-08.md`, `features/befunde.md`, die elf `qa-report.md`.

**Tragende Entscheidung:** Direktvertrieb und Store laufen parallel (PRD, Decision Log 7).
Sparkle darf im Store nicht enthalten sein → zwei Bauvarianten über das Compiler-Flag
`APPSTORE`. Eine Quelle, zwei Entitlements-Dateien, ein Bauskript mit Schalter.

## Ebene 1 · App-Store-Fähigkeit

- [x] T01 Entitlements für den Store: Sandbox an, `files.user-selected.read-write`, ohne `disable-library-validation`
      · **korrigiert am 2026-09-02:** stand ursprünglich auf `read-only`. Damit öffnet die
      Powerbox den Speichern-Dialog nicht — der Export blieb wirkungslos (2.1(a), T28)
- [x] T02 Security-Scoped Bookmarks in `ScanEngine` — Rescan überlebt den Neustart · behebt FB-B01-01, DM-03, FB-B01-07
      · **unvollständig gewesen:** die Duplikatsuche griff ohne Scope zu (T31); und die
      Sandbox war irrtümlich als Antwort auf TCC verbucht (T29)
- [x] T03 Sparkle hinter `#if !APPSTORE` · Voraussetzung für den Store
- [x] T04 `LSApplicationCategoryType` in der Info.plist · BF: FB-B10-11
- [x] T05 `scripts/build.sh --appstore` mit eigener Signatur- und Entitlement-Wahl
- [x] T06 Universelles Binary (`arm64` + `x86_64`) · BF-12

## Ebene 2 · Befunde in der Anwendung

- [x] T07 Filter durchgängig: B06 und B08 lesen die gefilterten Felder · BF-13
- [x] T08 Abbruch für Scan und Duplikatsuche · BF-15
- [x] T09 Schutz gegen gleichzeitige Scans · BF-16
- [x] T10 Zählweise: Pakete als ein Objekt, Symlinks überspringen · BF-17
- [x] T11 Fortschritt in der Duplikatsuche + sichtbare 1-KB-Schwelle · BF-14, FB-B06-01
- [x] T12 Barrierefreiheit: Beschriftungen für Tabelle, Diagramme, Zeitachse · BF-18
- [x] T13 Ordnerwahl aus der Menüleiste · BF-19
- [x] T14 Lesefehler sammeln und melden statt verschlucken · FB-B01 (AK-20)
- [x] T15 Filter beim Ordnerwechsel zurücksetzen · FB-B03-04
- [x] T16 Export: Prozentwert korrekt formatiert, `scannedAt` als Scanzeit, JSON-Fehler melden · BUG-09, FB-B07-01, FB-B07-04
- [x] T17 `.ts` eindeutig zuordnen, `other` einmalig berechnen · FB-B03-02, FB-B03-03
- [x] T18 `reset()` an den Menübefehl *Zurücksetzen* (Cmd-Shift-K) gebunden; löscht auch das Bookmark · FB-B01-06
- [x] T19 Farbsystem: Markenfarbe als erste Palettenfarbe, Grau nur für „Other" · DS-01, FB-B02-04, FB-B04-03

## Ebene 3 · Tests

- [x] T20 Tests für `FileCategory.matches`, `dateBucketKey`, `FileTypeGroup`, `ExportManager` · BF-23

## Ebene 4 · Website und Recht

- [x] T21 `LICENSE` anlegen (Source Available, Wortlaut aus dem PRD) · FB-05, BF-22
- [~] T22 Datenschutzerklärung vollständig; Impressum angelegt, **drei Platzhalter offen** (Anschrift, RCS-Nummer, USt-IdNr.) — nur vom Betreiber auszufüllen · BF-10
- [x] T23 Website: „Open source" richtigstellen, Filterzusage präzisieren, Version aus einer Quelle · BF-20, BF-22, FB-B11-04
- [x] T24 `lastmod`, CSP · FB-B11-06, FB-B11-07

## Ebene 5 · Projekt

- [x] T25 CI-Workflow wiederherstellen · BF-21
- [x] T26 `CHANGELOG.md` fortschreiben · FB-B10-10
- [x] T27 Dokumentation nachziehen: Architektur, Sparkle-Version, Palette · BF-12, FB-B10-08

## Ebene 6 · App Review 2026-09-01 — die beiden Beanstandungen

Apple hat die Einreichung von 2.1.0 abgelehnt (Submission 9b246573-21ad-44c4-a5a5-db0ac143b21c).
Beide Punkte gehen auf denselben Denkfehler zurück: **Sandbox-Entitlements wurden mit
TCC gleichgesetzt.** `features/B01-ordner-scannen/design.md:84` benannte die TCC-Ebene,
T01 hat sie dann als erledigt verbucht. Der Auditnachweis lief nur über einen kleinen
Testordner — der Fall des Prüfers, der Benutzerordner, wurde nie durchlaufen.

- [x] T28 `user-selected.read-write` statt `read-only` · Ablehnungsgrund **2.1(a)**.
      Gegengeprüft am 2026-09-02: dieselbe App einmal so und einmal so signiert — mit
      `read-only` erscheint nach „Export as CSV" kein Blatt, keine Datei, keine Meldung
- [x] T29 Sechs `NS*UsageDescription` in `Resources/Info.plist` · Ablehnungsgrund **5.1.1(ii)**.
      Jeder Text nennt was gelesen wird, wofür, ein Beispiel und die Grenze
- [x] T30 Speichern-Dialog als Blatt statt `runModal()` aus einer SwiftUI-`Menu`-Aktion · AS-06
- [x] T31 Duplikatsuche hält den Security Scope des gescannten Ordners; nicht lesbare
      Dateien werden gezählt und benannt statt still übersprungen
- [x] T32 Einmalige Erklärung vor dem ersten Ordnerzugriff (`AccessIntroView`),
      auch im Drag-and-drop-Pfad und im Menüleisten-Popover
- [x] T33 `Tests/BundleConfigTests` — Zweckbeschreibungen und Store-Entitlements am
      Bundle geprüft, damit diese Ablehnung nicht unbemerkt wiederkehrt

Mitgenommen, weil derselbe Prüfer darüber gestolpert wäre:

- Echter Scan-Fortschritt (`scannedSoFar` wurde nie hochgezählt)
- Abbruch erreicht den Hintergrundlauf (ein `Task.detached` erbt ihn nicht)
- Oberfläche durchgehend englisch (AS-08); die deutschen Fragmente sind weg
- Verweigerter Zugriff wird benannt, mit dem Weg in die Systemeinstellungen
- `File > Export as CSV…` (Cmd-E) / `Export as JSON…` (Shift-Cmd-E) als zweiter Weg
