# Mika+FileScope — Product Requirements Document

Stand: 2026-08-23 · Stufe Datenschutz: A · Stack-Profil: `swiftui-macos`
Artefaktpfad: `docs/`

> Rückwirkend aus dem Bestand erfasst (`sdd-erfassen`, Phase 1). Beschrieben ist, was der
> Code am 2026-08-23 tut — nicht, was er tun sollte. Abweichungen zwischen Anspruch und
> Umsetzung stehen unter *Fehlbestand*, nicht stillschweigend korrigiert im Fließtext.

## Vision

Mika+FileScope beantwortet eine einzige Frage, für die macOS kein gutes Werkzeug
mitbringt: **Was liegt eigentlich in diesem Ordner, und was davon frisst den Platz?**
Ein Ordner wird per Drag-and-drop abgelegt, einmal rekursiv gescannt, und aus diesem
einen Durchlauf entstehen fünf Sichten — Tabelle, Diagramme, Altersverteilung,
Duplikate, Menüleisten-Kurzfassung. Nichts verlässt den Rechner, und die App löscht
nichts: Sie zeigt, entschieden wird im Finder.

## Zielgruppe

| Gruppe | Situation | Was sie hier will |
|---|---|---|
| Mac-Nutzer mit voller Platte | Die Festplatte meldet sich, 400 GB sind weg und niemand weiß wohin | In zwei Minuten sehen, welcher Ordner und welcher Dateityp das Volumen ausmacht — ohne ein Werkzeug zu lernen |
| Fotografen und Medienschaffende | Jahre von Importen, RAW neben JPEG, dieselbe Aufnahme dreimal auf der Platte | Duplikate finden und die Bestände nach Alter sortiert sehen, um zu entscheiden, was ins Archiv kann |

Die Kategorie *Images* kennt `raw`, `cr2`, `nef`, `psd` und `heic`, die Kategorie *Videos*
zwölf Container-Formate — der Zuschnitt bedient diese zweite Gruppe bereits im Code.

## Im Scope

- Rekursives Scannen eines gewählten Ordners im Hintergrund, Fenster bleibt bedienbar
- Gruppierung aller gefundenen Dateien nach Endung, mit Anzahl, Summe und Anteil
- Sortierbare Tabelle über Endung, Anzahl, Größe und Prozentanteil
- Donut- und Balkendiagramm über die acht größten Typen plus Sammelposten „Other"
- Altersverteilung nach Änderungsdatum in sieben Zeitfenstern, nach Anzahl und Volumen
- Duplikaterkennung über SHA-256, zweistufig: erst nach Größe gruppieren, dann hashen
- Kategoriefilter über sieben semantische Gruppen plus „All"
- Export der Aufschlüsselung als CSV und als JSON über den Systemdialog
- Ein- und Ausblenden versteckter Dateien, mit automatischem Neuscan
- Optionale Menüleisten-Kurzfassung; die App läuft dann ohne Fenster weiter
- Automatische Updates über Sparkle, plus manueller Menübefehl „Check for Updates…"
- Auslieferung als DMG mit Build- und Signaturskripten
- Statische Marketing-Seite unter filescope.daumedia.lu

## Nicht im Scope

- **Dateien löschen, verschieben oder umbenennen** (die App zeigt Duplikate und öffnet
  den Finder; die Entscheidung bleibt beim Nutzer — steht so auch im Code: „FileScope
  does not delete files")
- **Cloud, Konten, Synchronisierung, Telemetrie** (die einzige Netzwerkverbindung ist
  der Update-Check; das ist zugleich das Versprechen der Website)
- **iOS- oder iPadOS-Variante** (das Dateisystem-Modell dort trägt das Produkt nicht)

Der **Mac App Store ist ausdrücklich kein Nicht-Ziel**, sondern beschlossenes Ziel.
Er steht als geplantes Feature `01` unter *Geplant* — und ist der einzige Eintrag im
ganzen Dokument, der noch nicht existiert.

## Erfolgskriterien

Festgelegt am 2026-08-23. Bewusst zwei Kriterien, beide prüfbar, keines davon eine
Reichweitenzahl:

1. **Der Update-Kanal erreicht bestehende Installationen — nachgewiesen an einem echten
   Durchlauf.** Eine auf 2.0.0 installierte App meldet ein Update auf die nächste
   Version, lädt es und startet damit neu. Heute ist das nachweislich nicht der Fall
   (FB-01 bis FB-03). Gilt für den jeweils aktiven Kanal: bis zur Store-Auslieferung
   für Sparkle, danach für den Kanal, über den die Nutzer tatsächlich versorgt werden.
2. **Kein offener Befund.** Jeder Eintrag unter *Fehlbestand* und in
   `features/befunde.md` ist entweder behoben oder mit Datum und Begründung akzeptiert,
   und die Erfassung ist bis zum Auditbericht durchgelaufen.

## Rahmenbedingungen

| Thema | Entscheidung |
|---|---|
| Stack-Profil | `swiftui-macos` — Details in `~/.claude/sdd/stacks/swiftui-macos.md` |
| Sprache/Version | Swift 6.0, strict concurrency, macOS 14 (Sonoma) als Minimum |
| Projektform | Swift Package Manager, kein `.xcodeproj`, flaches `path: "Sources"` |
| Backend | keins — die App ist vollständig lokal |
| Datenhaltung | `UserDefaults`: ein einziger Schlüssel, `showMenubar`. Scanergebnisse leben nur im Arbeitsspeicher und sind nach dem Beenden weg |
| Umgebungen | keine getrennten Umgebungen; gebaut wird lokal oder in GitHub Actions |
| Datenregion | entfällt — es werden keine Daten übertragen |
| Sprachen | Oberfläche ausschließlich Englisch, nicht lokalisiert |
| Monetarisierung | kostenlos |
| Lizenz | **Source Available**, beschlossen am 2026-08-23: Nutzung der App uneingeschränkt frei, auch beruflich; Quelltext lesen und für den Eigengebrauch selbst bauen erlaubt; Weiterverbreitung und abgeleitete Werke nur mit schriftlicher Erlaubnis. Die `LICENSE`-Datei fehlt noch — siehe FB-05 |
| Externe Dienste | Sparkle-Update-Feed auf `raw.githubusercontent.com` (holt eine XML-Datei, sendet keine Nutzerdaten); Vercel als Hoster der Marketing-Seite |
| Signatur | Ad-hoc (`codesign --sign -`), Hardened Runtime an, **nicht notarisiert** |
| Sandbox | aus (`com.apple.security.app-sandbox = false`), zusätzlich `disable-library-validation = true` |
| Vertrieb | heute: DMG über GitHub Releases, Aktualisierung über Sparkle. Beschlossen: zusätzlich der Mac App Store (Feature `01`) |

## Datenschutz — Kurzfassung

**Stufe A — kein Personenbezug im Sinne einer Verarbeitung.** Die App führt keine Konten,
fragt nichts ab, sendet nichts. Sie liest Metadaten der Dateien im gewählten Ordner —
Pfad, Endung, Größe, Änderungsdatum — und bei der Duplikatsuche zusätzlich den
vollständigen Inhalt, um ihn zu hashen. All das bleibt im Arbeitsspeicher des Geräts.

Vollständig ausgeführt in **`docs/datenschutz.md`** — dort auch der Nachweis, dass der
eigene Code keinen einzigen Netzwerkaufruf enthält, und die Liste dessen, was für den
App Store (Feature `01`) noch fehlt.

Damit verkürzt sich der Katalog aus `~/.claude/sdd/sicherheit.md` auf die Abschnitte
**4 (Missbrauch und Kosten)** und **6 (Geheimnisse)**. Die Abschnitte 1, 2, 3 und 5
werden pro Feature mit „trifft nicht zu, weil keine Personendaten das Gerät verlassen"
beantwortet — nicht weggelassen.

Zwei Einschränkungen, die trotz Stufe A gelten:

- **Der JSON-Export enthält den vollständigen Ordnerpfad** (`scannedFolder`), also in
  aller Regel den macOS-Benutzernamen. Wer die Datei weitergibt, gibt den mit. Das ist
  kein Fehler, aber es gehört benannt.
- **Der Update-Kanal ist der einzige Weg, auf dem fremder Code auf den Rechner kommt.**
  Bei Stufe A ist das der Punkt mit dem höchsten Risiko der ganzen Anwendung — deshalb
  steht er in der Rückerfassung an erster Stelle.

## Feature-Inventar

Kein Plan, sondern eine Bestandsaufnahme: Alles hier existiert und läuft. Alle Einträge
stehen auf `bestand`, die IDs tragen das Präfix `B`.

| ID | Feature | Prio | Kurzbeschreibung | Abhängig von |
|---|---|---|---|---|
| B01 | Ordner scannen | P0 | Ordnerwahl per Dialog oder Drag-and-drop, rekursiver Hintergrundscan, Neuscan, Schalter für versteckte Dateien | — |
| B02 | Aufschlüsselung nach Dateityp | P0 | Sortierbare Tabelle mit Endung, Anzahl, Größe, Anteil; Kennzahlenleiste darüber | B01 |
| B03 | Kategoriefilter | P1 | Sieben semantische Gruppen plus „All", als Chip-Leiste; wirkt auf Tabelle, Diagramme, Kennzahlen und Export | B01, B02 |
| B04 | Diagramme | P0 | Donut nach Größenanteil und horizontales Balkendiagramm, Top 8 plus „Other" | B01 |
| B05 | Zeitachse | P1 | Altersverteilung nach Änderungsdatum in sieben Fenstern, je nach Anzahl und nach Volumen | B01 |
| B06 | Duplikatsuche | P1 | Zweistufig über Größe und SHA-256, Ergebnisblatt mit verschwendetem Platz und „Im Finder zeigen" | B01 |
| B07 | Export CSV und JSON | P0 | Speichern-Dialog, CSV mit lesbaren Größen, JSON mit Pfad, Zeitstempel und Summen | B01, B02 |
| B08 | Menüleisten-Kurzfassung | P2 | Optionales Menüleistensymbol mit Kennzahlen und Top 5; App läuft ohne Fenster weiter | B01 |
| B09 | Automatische Updates | P1 | Sparkle 2.9, Feed auf GitHub raw, Menübefehl „Check for Updates…", EdDSA-Schlüssel in der Info.plist | — |
| B10 | Auslieferung und Signatur | P0 | `build.sh` baut das Bundle und bettet Sparkle ein, zwei DMG-Skripte, Ad-hoc-Signatur mit Hardened Runtime | B09 |
| B11 | Marketing-Website | P2 | Statische Seite auf Vercel, Screenshots, OG-Bild, Download-Link auf das aktuelle Release | B10 |

**Reihenfolge der Rückerfassung — nach Risiko, nicht nach Nummer:**

```
B09 → B10 → B01 → B06 → B07 → B11 → B03 → B02 → B05 → B04 → B08
```

Begründung in `features/index.md`.

## Fehlbestand

Was beim Lesen des Codes auffiel und **nicht** in ein Akzeptanzkriterium umgedeutet
wurde. Kein Eintrag hier ist bereits geprüft — die Prüfung ist Sache von `sdd-qa`.

| # | Beobachtung | Betrifft |
|---|---|---|
| FB-01 | `appcast.xml` enthält kein einziges `<item>`. Der Feed ist syntaktisch gültig und inhaltlich leer — kein installierter Client erfährt je von einem Update, auch nicht von v2.0.0 | B09 |
| FB-02 | `CFBundleVersion` steht auf `1`, während `CFBundleShortVersionString` bereits `2.0.0` ist. Sparkle vergleicht die Build-Nummer; bleibt sie konstant, gilt jedes Update als „nicht neuer" | B09 |
| FB-03 | Der Feed zeigt auf den Branch `master`, gearbeitet wird auf `main`. Beide existieren und sind auseinandergelaufen (4 Commits nur auf `main`, 3 nur auf `master`); die Fassung auf `master` verweist noch auf die alte Organisation `Mukaarts` | B09, B10 |
| FB-04 | Ad-hoc-Signatur ohne Notarisierung, dazu `disable-library-validation = true` und Sandbox aus. Gatekeeper blockiert den ersten Start; die Kombination ist für ein öffentlich verteiltes Binary die schwächste Stufe. Wird durch Feature `01` aufgelöst | B10, 01 |
| FB-05 | Die Website wirbt mit „Free · Open source", README und `Info.plist` sagen „All rights reserved", eine `LICENSE`-Datei existiert nicht. Beschluss vom 2026-08-23: **Source Available**. Zu tun sind drei Dinge — `LICENSE` im Wortlaut aus dem Decision Log anlegen, „Open source" auf der Website durch „Source available" ersetzen, und den Hinweis „build it yourself" beibehalten, weil der Eigenbau ausdrücklich erlaubt ist | B11 |
| FB-06 | Die Website verspricht „Table, charts, summary and export all follow the filter". Die Zeitachse folgt ihm nicht: `HistogramView` bekommt `engine.dateBuckets`, nicht die gefilterte Menge. Auch die Duplikatsuche arbeitet auf allen gescannten Dateien | B03, B05, B06 |
| FB-07 | `DuplicateDetector.progress` wird auf `0` gesetzt und erst nach dem Ende auf `1.0`. Die Fortschrittsleiste im Ergebnisblatt steht die gesamte Laufzeit auf null und suggeriert einen Fortschritt, den niemand berechnet | B06 |
| FB-08 | Es gibt kein `Tests/`-Verzeichnis und keinen einzigen Test. `swift test` hat nichts zu tun — jeder Nachweis in der QA muss manuell erbracht werden | alle |
| FB-09 | `.github/workflows/release.yml` ist in `CLAUDE.md` und `README.md` beschrieben, im Arbeitsverzeichnis aber nicht vorhanden (Commit `8ddde5f` hat den Workflow wieder entfernt) | B10 |
| FB-10 | `CHANGELOG.md` führt sämtliche Funktionen ab Version 1.0.0 unter `[Unreleased]`, obwohl Release v2.0.0 seit dem 2026-03-23 veröffentlicht ist und Website wie `Info.plist` 2.0.0 nennen | B10, B11 |
| FB-11 | Version, Download-URL und Dateigröße stehen fest verdrahtet in `website/index.html`. Angegeben sind 2,1 MB, das Release-Asset misst 2.168.264 Bytes — das passt heute und bricht beim nächsten Release still | B11 |
| FB-12 | `startAccessingSecurityScopedResource()` wird beim Scan aufgerufen, ohne dass jemals ein Security-Scoped Bookmark angelegt wurde. Ohne Sandbox ist der Aufruf wirkungslos; er sieht nach einer Absicherung aus, die nicht existiert. Wird mit Feature `01` von einer Attrappe zur Notwendigkeit | B01, 01 |

## Geplant

Der einzige Eintrag im Dokument, der noch nicht existiert. Numerische ID ohne `B`, weil
er durch die volle Kette läuft — Spec, Systemdesign, Aufgabenplan, Bau, QA.

| ID | Feature | Prio | Kurzbeschreibung | Abhängig von |
|---|---|---|---|---|
| 01 | Mac App Store | P1 | Sandbox aktivieren, Store-Variante signieren und einreichen, Aktualisierung über den Store statt über Sparkle | B01, B09, B10 |

Was diese Entscheidung nach sich zieht, in der Reihenfolge des Aufwands:

- **Die Sandbox muss an.** Technisch trägt FileScope das: Ein per `NSOpenPanel` oder per
  Drag-and-drop gewählter Ordner ist mit `com.apple.security.files.user-selected.read-only`
  rekursiv lesbar. Was heute wirkungslos im Code steht — `startAccessingSecurityScopedResource()`
  aus FB-12 — wird dann tatsächlich gebraucht, zusammen mit Security-Scoped Bookmarks,
  damit „Rescan" einen Neustart überlebt.
- **`disable-library-validation` muss weg.** Der Store nimmt das Entitlement nicht an.
- **Sparkle fällt in der Store-Variante weg.** Der Store aktualisiert selbst; ein
  eigener Update-Mechanismus ist dort unzulässig. B09 bleibt für den Direktvertrieb
  bestehen, sofern er weitergeführt wird.
- **Ad-hoc-Signatur reicht nicht mehr.** Nötig sind Apple Developer Program,
  Developer-ID- bzw. Store-Zertifikate und für den Direktkanal die Notarisierung — das
  räumt zugleich FB-04 ab.

Ob der Direktvertrieb parallel weiterläuft oder abgelöst wird, entscheidet die Spec von
Feature `01` und wird dort im Decision Log festgehalten. Für das PRD ist die Weiche
gestellt: Der Store ist ein Ziel.

## Offene Punkte

Derzeit keine. Die drei Punkte der Erfassung wurden am 2026-08-23 entschieden:

| # | Frage | Entscheidung | Begründung |
|---|---|---|---|
| 1 | Welcher Lizenztext gilt? | **Source Available** — eigener Text, kein OSS-Standard | Nutzung der App soll für alle frei sein, auch beruflich; die Rechte am Code bleiben beim Urheber. PolyForm Noncommercial hätte genau die Zielgruppe ausgeschlossen, für die das Werkzeug gebaut ist — Fotografen im Beruf |
| 2 | Mac App Store? | **Ja, angestrebt** — als Feature `01` durch die volle Kette | Die technische Sperre ist nicht der Ordnerzugriff, sondern Sparkle und `disable-library-validation`; beides ist auflösbar |
| 3 | Woran wird Erfolg gemessen? | Funktionierender Update-Kanal und kein offener Befund | Beides ist prüfbar und liegt in eigener Hand. Downloadzahlen hängen an Reichweite, nicht an der Qualität des Produkts |

### Wortlaut der beschlossenen LICENSE

Noch nicht angelegt (FB-05) — die Erfassung ändert keinen Bestand. Beschlossen ist:

```
Mika+FileScope — Source Available License
Copyright 2025 dauMedia / Mika

You may:
  • use the application for any purpose, including commercial
  • read the source code
  • build it yourself for your own use

You may not, without written permission:
  • redistribute the source or binaries
  • publish modified or derived versions

Provided "as is", without warranty of any kind.
```
