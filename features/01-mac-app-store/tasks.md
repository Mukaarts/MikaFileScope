# 01 · Mac App Store — Aufgabenplan

Status: `building` · Stand: 2026-08-24 · 26 von 27 erledigt, 1 teilweise

Ziel: App-Store-fähig **und** alle offenen Befunde aus dem Audit vom 2026-08-24 geschlossen.
Grundlage: `docs/audit-2026-08.md`, `features/befunde.md`, die elf `qa-report.md`.

**Tragende Entscheidung:** Direktvertrieb und Store laufen parallel (PRD, Decision Log 7).
Sparkle darf im Store nicht enthalten sein → zwei Bauvarianten über das Compiler-Flag
`APPSTORE`. Eine Quelle, zwei Entitlements-Dateien, ein Bauskript mit Schalter.

## Ebene 1 · App-Store-Fähigkeit

- [x] T01 Entitlements für den Store: Sandbox an, `files.user-selected.read-only`, ohne `disable-library-validation`
- [x] T02 Security-Scoped Bookmarks in `ScanEngine` — Rescan überlebt den Neustart · behebt FB-B01-01, DM-03, FB-B01-07
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
