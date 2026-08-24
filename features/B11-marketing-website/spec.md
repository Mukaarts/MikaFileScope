# B11 · Marketing-Website — Spezifikation

Status: `review` · Stand: 2026-08-24 · geprüft, siehe `qa-report.md`

> Beschrieben ist, was der Bestand am 2026-08-23 tut — nicht, was er tun sollte.
> **Alle Kriterien in diesem Dokument beschreiben Verhalten, das so gewollt ist.**
> Was fragwürdig war, wurde am 2026-08-23 entschieden und steht im *Fehlbestand*.

## Zweck

Eine statische Seite unter **filescope.daumedia.lu** erklärt, was FileScope kann, zeigt
echte Bildschirmfotos und führt zum Download des DMG. Sie ist die einzige öffentliche
Darstellung des Produkts außerhalb von GitHub — und damit die Stelle, an der Zusagen
gemacht werden, die der Code einlösen muss.

## Abhängigkeiten

| Braucht | Status | Warum |
|---|---|---|
| B10 · Auslieferung und Signatur | `rekonstruiert` | verlinkt das DMG und erklärt den Gatekeeper-Umweg |

## User Stories

- **US-01** · Als Interessent möchte ich in einem Blick verstehen, was das Werkzeug tut.
- **US-02** · Als Interessent möchte ich echte Bildschirmfotos sehen, keine Attrappen.
- **US-03** · Als Nutzer möchte ich das DMG mit einem Klick herunterladen.
- **US-04** · Als Nutzer möchte ich vorab wissen, dass der erste Start einen Zusatz-
  schritt braucht, damit mich die Gatekeeper-Meldung nicht überrascht.

## Nicht im Scope

- **Bezahlvorgänge, Konten, Newsletter, Analytics** — die Seite sammelt nichts.
- **Dokumentation der App** — dafür `README.md` im Repository.
- **Ein Build-Schritt.** Ausgeliefert wird, was im Verzeichnis liegt.

## Akzeptanzkriterien

### Aufbau und Auslieferung

- **AK-01** · Angenommen, die Seite wird aufgerufen, wenn sie lädt, dann besteht sie aus
  fünf Abschnitten: Kopfbereich, *Features*, *Screenshots*, *How it works*, *Install*.
- **AK-02** · Angenommen, das Verzeichnis `website/` wird veröffentlicht, wenn Vercel
  baut, dann findet **kein Build-Schritt** statt — HTML, CSS und JS werden unverändert
  ausgeliefert (Framework Preset *Other*, Root Directory `website`).
- **AK-03** · Angenommen, eine Seite wird ausgeliefert, wenn die Antwortkopfzeilen
  gesetzt werden, dann enthalten sie `X-Content-Type-Options: nosniff`,
  `Referrer-Policy: strict-origin-when-cross-origin`, `X-Frame-Options: SAMEORIGIN` und
  eine `Permissions-Policy`, die Standort, Mikrofon, Kamera und Interessengruppen
  abschaltet.
- **AK-04** · Angenommen, eine Datei unter `/assets/` wird abgerufen, wenn sie
  ausgeliefert wird, dann trägt sie `Cache-Control: public, max-age=31536000, immutable`.

### Inhalt und Zusagen

- **AK-05** · Angenommen, die Seite wird gelesen, wenn der Abschnitt *Privacy & Security*
  erscheint, dann sagt sie zu: kein Konto, keine Analytik, keine Telemetrie, und die App
  selbst stelle keine Netzwerkanfragen außer der Update-Prüfung.
- **AK-06** · Angenommen, die Seite beschreibt die Duplikatsuche, wenn sie das tut, dann
  stellt sie klar, dass FileScope **nichts löscht**.
- **AK-07** · Angenommen, die Seite nennt die Systemvoraussetzungen, wenn sie das tut,
  dann nennt sie macOS 14 Sonoma oder neuer **und Apple silicon**.
- **AK-08** · Angenommen, die Seite erklärt den ersten Start, wenn sie das tut, dann
  benennt sie die Ad-hoc-Signatur und den Umweg über Rechtsklick → Öffnen.
- **AK-09** · Angenommen, die Bildschirmfotos werden gezeigt, wenn sie geladen werden,
  dann sind es echte Aufnahmen der App in Dark Mode als WebP.

### Bedienung

- **AK-10** · Angenommen, die Seite wird gescrollt, wenn mehr als 8 Pixel zurückgelegt
  sind, dann erhält die Kopfleiste eine Trennlinie.
- **AK-11** · Angenommen, die Bildschirmfoto-Reiter werden bedient, wenn ein Reiter
  gewählt wird, dann wechselt das Bild und `aria-selected` wandert mit.
- **AK-12** · Angenommen, die Reiter haben den Fokus, wenn Pfeiltasten, Pos1 oder Ende
  gedrückt werden, dann wandert die Auswahl nach dem WAI-ARIA-Muster.
- **AK-13** · Angenommen, die Schaltfläche zum Kopieren des Build-Befehls wird gewählt,
  wenn die Zwischenablage verfügbar ist, dann wird der Befehl kopiert und die Beschriftung
  wechselt für 1,8 Sekunden auf „Copied".
- **AK-14** · Angenommen, JavaScript ist abgeschaltet, wenn die Seite geladen wird, dann
  bleibt das erste Bildschirmfoto sichtbar, alle Links funktionieren, und die
  Kopierschaltfläche wird ausgeblendet.
- **AK-15** · Angenommen, die Seite wird mit der Tastatur bedient, wenn der erste
  Tabulatorsprung erfolgt, dann erscheint ein „Skip to content"-Link.

### Auffindbarkeit

- **AK-16** · Angenommen, ein Suchdienst liest die Seite, wenn er die Metadaten
  auswertet, dann findet er Titel, Beschreibung, Canonical-URL, Open-Graph- und
  Twitter-Card-Angaben sowie ein JSON-LD-Objekt vom Typ `SoftwareApplication`.
- **AK-17** · Angenommen, `robots.txt` wird gelesen, wenn ein Crawler sie auswertet,
  dann ist alles freigegeben und die Sitemap verlinkt.

### Zu Fehlern erklärt — nicht mehr als Kriterium geführt

Die Nummern **AK-18, AK-19, AK-20, AK-21, AK-22, AK-23** beschrieben Verhalten, das der Code tatsächlich zeigt, und
waren als ⚠-Kriterien aufgenommen. Am 2026-08-23 wurden sie als **Fehler** eingestuft und
in den *Fehlbestand* überführt. Die Nummern bleiben unbesetzt, damit Verweise aus
`design.md` und aus späteren Berichten eindeutig bleiben.

**Für `sdd-qa` heißt das:** keine zu bestätigenden Kriterien, sondern eine Suchliste.

## Edge Cases

- **EC-01** · WebP nicht unterstützt → kein Rückfallformat hinterlegt; die Bilder
  bleiben leer. Betrifft nur sehr alte Browser.
- **EC-02** · Zwischenablage nicht verfügbar → Kopierschaltfläche wird versteckt
  (`copyBtn.hidden = true`), sauber gelöst.
- **EC-03** · Release wird zurückgezogen → der fest verdrahtete Download-Link läuft ins
  Leere.
- **EC-04** · Domain wechselt → drei Dateien müssen gemeinsam geändert werden
  (`index.html`, `robots.txt`, `sitemap.xml`); `website/README.md` beschreibt das korrekt.

## Fehlbestand

- **FB-B11-01 · Keine Datenschutzerklärung, kein Impressum.** Siehe AK-21 und DZ-01.
  Folge: rechtliches Risiko in der EU und ein Hindernis für Feature `01`.

- **FB-B11-02 · „Open source" ohne Lizenz.** Siehe AK-18. Folge: Die Aussage ist
  unzutreffend; Dritte könnten daraus Nutzungsrechte ableiten, die nicht bestehen.

- **FB-B11-03 · Version, Download-URL und Dateigröße fest verdrahtet.** Siehe AK-20.
  Folge: Jedes Release erfordert vier Änderungen von Hand, sonst zeigt die Seite auf ein
  altes Paket.

- **FB-B11-04 · Die Filterzusage ist unvollständig.** Siehe AK-19.

- **FB-B11-05 · Palette weicht von der App ab, obwohl Gleichlauf gefordert ist.**
  Siehe AK-22.

- **FB-B11-06 · `lastmod` in der Sitemap veraltet.** Siehe AK-23.

- **FB-B11-07 · Keine Content-Security-Policy.** `vercel.json` setzt vier
  Sicherheitskopfzeilen, aber keine CSP. Folge: gering, weil die Seite statisch ist und
  keine fremden Quellen einbindet — aber es wäre die wirksamste der Kopfzeilen.

- **FB-B11-08 · Kein automatischer Abgleich zwischen Zusage und Code.**
  `website/README.md` führt drei prüfbare Aussagen mit dem jeweiligen Prüfbefehl auf —
  vorbildlich, aber niemand führt sie aus. Folge: Die Seite kann unbemerkt unwahr werden.

### Aus Kriterien zu Fehlern erklärt (2026-08-23)

- **war AK-18** · Angenommen, ein Besucher liest den Kopfbereich, wenn dort
  „Native macOS utility · Free · **Open source**" steht, dann ist diese Angabe
  **unzutreffend**: Es gibt keine Lizenzdatei, README und `Info.plist` sagen
  „All rights reserved", und der Beschluss vom 2026-08-23 lautet *Source Available*.
  *(Siehe FB-05 im PRD. Zur Klärung vorgelegt — die Entscheidung ist gefallen, die
  Umsetzung auf der Seite steht aus.)*

- **war AK-19** · Angenommen, ein Besucher liest über den Kategoriefilter, wenn dort steht
  „Table, charts, summary and export all follow the filter", dann trifft das zu — die
  Seite verschweigt jedoch, dass **Zeitachse und Duplikatsuche ihm nicht folgen**.
  *(Siehe AK-17 in B06 und FB-06 im PRD. Am 2026-08-23 als Fehler eingestuft.)*

- **war AK-20** · Angenommen, eine neue Version erscheint, wenn die Seite unverändert
  bleibt, dann zeigt sie weiterhin **Version 2.0.0**, verlinkt
  `Mika+FileScope-v2.0.0.dmg` und nennt 2,1 MB — alle drei Angaben stehen fest im
  Quelltext, an drei verschiedenen Stellen plus einmal im JSON-LD.
  *(Am 2026-08-23 als Fehler eingestuft.)*

- **war AK-21** · Angenommen, die Seite wird unter einer `.lu`-Domain geschäftlich
  betrieben, wenn ein Besucher nach Anbieterangaben sucht, dann findet er **weder
  Impressum noch Datenschutzerklärung**.
  *(Luxemburg setzt die E-Commerce-Richtlinie um; Anbieterkennzeichnung und
  Datenschutzhinweis sind für geschäftsmäßige Seiten vorgeschrieben. Für den App Store
  (Feature `01`) ist eine erreichbare Datenschutzerklärung ohnehin Pflicht — siehe
  DZ-01. Am 2026-08-23 als Fehler eingestuft.)*

- **war AK-22** · Angenommen, `CLAUDE.md` verlangt „Palette mirrors
  `Sources/MikaPlusColors.swift`; keep the two in sync", wenn beide verglichen werden,
  dann **stimmen sie nicht überein**: `--text` ist `#E8F3EE` statt `#E1F5EE`, `--muted`
  ist `#A3B2AE` und existiert in der App gar nicht; `tealSurface` und `destructive`
  fehlen auf der Seite.
  *(Fünf von neun Werten stimmen, zwei weichen ab, zwei fehlen. Am 2026-08-23 als Fehler eingestuft.)*

- **war AK-23** · Angenommen, `sitemap.xml` wird ausgewertet, wenn `lastmod` gelesen wird,
  dann steht dort **2026-07-30**, obwohl die Seite danach noch geändert wurde
  (Domainumstellung, Kontoumbenennung).
  *(Am 2026-08-23 als Fehler eingestuft.)*

## Offene Fragen

- **OF-01** · ~~Wo sollen Impressum und Datenschutzerklärung liegen?~~
  **Als Unterseiten der Landingpage**, entschieden am 2026-08-24: `/privacy` und `/imprint`, verlinkt aus der Fußzeile jeder Seite und in der Sitemap eingetragen.
- **OF-02** · ~~Soll die Versionsangabe automatisch aus dem letzten Release gezogen werden (Vercel-Build-Schritt) oder bewusst statisch ~~
  **Automatisiert am 2026-08-24.** `scripts/update-website-version.sh` setzt Version, Dateigröße, Download-URL und JSON-LD aus der `Info.plist` — vier Stellen aus einer Quelle. Bewusst als Skript und nicht als Build-Schritt: Die Seite bleibt ohne Werkzeugkette ausliefer­bar.

## Decision Log

| # | Frage | Entscheidung | Begründung |
|---|---|---|---|
| 1 | Wie wird die Seite gebaut? | gar nicht — reines HTML/CSS/JS | Kein Build, keine Abhängigkeiten, kein Veralten der Werkzeugkette. Für eine einseitige Landingpage angemessen |
| 2 | Wo wird gehostet? | Vercel, Root Directory `website` | Automatische Auslieferung bei jedem Push, kostenloses Zertifikat |
| 3 | Echte Bildschirmfotos statt Attrappen | Attrappen wären einfacher | Die Seite sagt es ausdrücklich („Real screenshots — no mockups"); Glaubwürdigkeit vor Bequemlichkeit |
| 4 | JavaScript nur als Verbesserung | JS-getriebene Seite | Ohne JS bleibt die Seite vollständig benutzbar. Sauber umgesetzt (AK-14) |
| 5 | Gatekeeper-Umweg offen benennen | verschweigen | Ehrlicher und erspart Rückfragen. Entfällt, sobald notarisiert wird (FB-B10-01) |
| — | Sind die ⚠-Kriterien gewolltes Verhalten? | **Nein, 6 davon sind Fehler** (2026-08-23) | Gebündelt entschieden über alle Features hinweg; die Muster stehen in `features/index.md` |
