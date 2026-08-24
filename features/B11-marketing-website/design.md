# B11 · Marketing-Website — Systemdesign

Status: `review` · Stand: 2026-08-24 · geprüft, siehe `qa-report.md`

**Kein Code in diesem Dokument.**

## Überblick

984 Zeilen in drei Dateien, kein Build-Schritt, keine Abhängigkeit: 320 Zeilen HTML,
595 Zeilen CSS, 69 Zeilen JavaScript. Vercel liefert das Verzeichnis unverändert aus.
Das JavaScript ist reine Verbesserung — ohne es bleibt die Seite vollständig benutzbar.

Die Seite ist handwerklich die sauberste Komponente des Projekts: Sicherheitskopfzeilen
gesetzt, ARIA-Muster korrekt umgesetzt, Skip-Link vorhanden, Bilder als WebP mit
Langzeit-Cache. Ihre Schwächen liegen nicht in der Technik, sondern in den **Aussagen**,
die sie über die App macht.

## Seiten und Routen

| Route | Zweck | Zugang |
|---|---|---|
| `/` | die gesamte Landingpage | öffentlich |
| `/styles.css`, `/script.js` | Gestaltung und Verbesserung | öffentlich |
| `/assets/*` | Symbole, OG-Bild, Bildschirmfotos | öffentlich, ein Jahr Cache |
| `/robots.txt`, `/sitemap.xml` | Auffindbarkeit | öffentlich |
| **`/privacy`, `/imprint`** | — | **existieren nicht** (FB-B11-01) |

## Struktur

```
index.html
├── <head>   Titel · Beschreibung · Canonical · OG ×6 · Twitter ×3
│             theme-color #0F0F1A · Favicon · Apple-Touch-Icon
│             JSON-LD SoftwareApplication (Version 2.0.0, Preis 0 USD)
├── skip-link                              „Skip to content"
├── header.nav#nav                         Marke · 4 Links · Download-Schaltfläche
├── section.hero#top                       Schlagzeile · Version/Anforderungen · CTA
│   └── drei Zusagen                       lokal · löscht nichts · quelloffen ⚠
├── section#features                       acht Karten
├── section#screenshots                    Reiter (WAI-ARIA) + 4 WebP-Aufnahmen
├── section#how                            drei Schritte
├── section#install                        Download · Gatekeeper-Hinweis · Build-Befehl
└── footer                                 © 2025 dauMedia / Mika
```

## Verhalten · `script.js`

| Baustein | Auslöser | Wirkung | Ohne JS |
|---|---|---|---|
| Kopfleisten-Linie | `scroll > 8px` | Klasse `is-scrolled` | Leiste bleibt linienlos |
| Bildschirmfoto-Reiter | Klick, Pfeiltasten, Pos1, Ende | `aria-selected`, `tabIndex`, `hidden` | erstes Bild bleibt sichtbar |
| Kopierschaltfläche | Klick | `navigator.clipboard.writeText`, 1,8 s „Copied" | wird versteckt |

Alle drei Bausteine prüfen zuerst, ob ihr Element existiert — die Datei läuft auch auf
einer veränderten Seite fehlerfrei.

## Auslieferung · `vercel.json`

| Kopfzeile | Wert | Geltung |
|---|---|---|
| `X-Content-Type-Options` | `nosniff` | alles |
| `Referrer-Policy` | `strict-origin-when-cross-origin` | alles |
| `X-Frame-Options` | `SAMEORIGIN` | alles |
| `Permissions-Policy` | Standort, Mikrofon, Kamera, Interessengruppen aus | alles |
| `Cache-Control` | `public, max-age=31536000, immutable` | `/assets/*` |
| **`Content-Security-Policy`** | — | **nicht gesetzt** (FB-B11-07) |

Dazu `cleanUrls: true` und `trailingSlash: false`.

## Palette — Soll und Ist

`CLAUDE.md` verlangt Gleichlauf mit `Sources/MikaPlusColors.swift`. Der Vergleich:

| App-Token | App | Website | Stand |
|---|---|---|---|
| `tealPrimary` | `#1D9E75` | `--teal: #1D9E75` | ✓ |
| `tealLight` | `#5DCAA5` | `--teal-light: #5DCAA5` | ✓ |
| `tealLightest` | `#9FE1CB` | `--teal-lightest: #9FE1CB` | ✓ |
| `darkBg` | `#1A1A2E` | `--bg: #1A1A2E` | ✓ |
| `darkBgDeep` | `#0F0F1A` | `--bg-deep: #0F0F1A` | ✓ |
| `textPrimary` | `#E1F5EE` | `--text: #E8F3EE` | **✗ abweichend** |
| `textSecondary` | `#9FE1CB` | `--muted: #A3B2AE` | **✗ abweichend** |
| `tealSurface` | `#E1F5EE` | — | **fehlt** |
| `destructive` | `#E24B4A` | — | **fehlt** |

Die Website führt zusätzlich `--surface`, `--line`, `--muted-dim`, `--wrap`, `--radius`
und zwei Schriftstapel, die in der App keine Entsprechung haben — dort steht dem der
Wildwuchs aus `docs/design-system.md` gegenüber. Beide Seiten haben also je ein eigenes,
untereinander nicht abgestimmtes System.

## Zugriffsregeln

Keine. Die Seite ist vollständig öffentlich, hat keine Formulare, keine Anmeldung, keine
Datenbank und setzt keine Cookies.

## Missbrauchsschutz

| Risiko | Schutz | Lücke |
|---|---|---|
| MIME-Verwechslung | `nosniff` | keine |
| Einbettung in fremde Seiten | `X-Frame-Options` | keine |
| Fremde Skripte | keine externen Quellen eingebunden | keine CSP, die es erzwingt (FB-B11-07) |
| Verweis auf ein zurückgezogenes Release | — | keiner (EC-03) |
| Formularmissbrauch, Spam | entfällt — keine Formulare | — |
| Kosten pro Aufruf | Vercel-Freikontingent | keine Obergrenze konfiguriert |

## Externe Dienste

| Dienst | Wofür | Was hingeht |
|---|---|---|
| Vercel | Hosting, Zertifikat | IP, User-Agent, Referrer des Besuchers |
| GitHub Releases | Download-Ziel | dito, beim Klick auf Download |

**Keine** Analytik, keine Schriftarten von fremden Servern, keine Einbettungen — die
Schriften kommen aus dem System (`-apple-system`, `SF Pro`).

## Erkennbare Entscheidungen

| # | Entscheidung | Alternative | Warum so |
|---|---|---|---|
| 1 | Kein Build-Schritt | Astro, Eleventy, Next.js | Eine Seite braucht kein Gerüst. Nichts kann veralten oder brechen |
| 2 | Vercel statt GitHub Pages | Pages | Eigene Domain und Kopfzeilen ohne Umweg; Pages kann keine Kopfzeilen setzen — genau deshalb war `docs/` frei und konnte den Artefaktpfad aufnehmen |
| 3 | WebP ohne Rückfallformat | zusätzlich PNG/JPEG | Deutlich kleiner; alle unterstützten macOS-Browser können WebP |
| 4 | Dark-Mode-Aufnahmen | beide Erscheinungsbilder | Passt zur dunklen Seite. Die App kann beides — die Seite zeigt nur eines |
| 5 | Version und Größe fest im HTML | aus der GitHub-API ziehen | Kein Build, keine Laufzeitabfrage — dafür Handarbeit bei jedem Release (FB-B11-03) |
| 6 | JSON-LD `SoftwareApplication` | keine strukturierten Daten | Suchdienste können Preis, Betriebssystem und Version auswerten |
| 7 | Kein Impressum | — | **Grund nicht erkennbar.** Vermutlich übersehen; bei einer `.lu`-Domain rechtlich bedeutsam (FB-B11-01) |

## Abdeckung der Akzeptanzkriterien

| AK | Erfüllt durch |
|---|---|
| AK-01 | fünf `<section>`-Elemente in `index.html` |
| AK-02 | `vercel.json` ohne `buildCommand`; Root Directory `website` |
| AK-03, AK-04 | `vercel.json` → `headers` |
| AK-05 | Abschnitt *Privacy & Security* im Kopfbereich |
| AK-06 | Kartentext der Duplikatsuche |
| AK-07 | Zeile unter dem Download-Knopf |
| AK-08 | Abschnitt *First launch takes one extra click* |
| AK-09 | `assets/shots/*.webp` |
| AK-10 | `script.js:9-16` |
| AK-11, AK-12 | `script.js:18-50` |
| AK-13 | `script.js:52-68` |
| AK-14 | Aufbau: `hidden`-Umschaltung nur über JS, Voreinstellung sichtbar |
| AK-15 | `<a class="skip-link">` |
| AK-16 | `<head>`-Metadaten und JSON-LD |
| AK-17 | `robots.txt` |


**AK-18 bis AK-23 sind entfallen.** Sie wurden am 2026-08-23 als Fehler eingestuft
und in den *Fehlbestand* der Spec überführt; ihre Nummern bleiben unbesetzt. Was sie
beschrieben, wird von keiner Komponente erfüllt — es ist der Defekt selbst.

**Ohne Zuordnung:** `scripts/GenerateOGImage.swift` erzeugt `assets/og-image.jpg` aus
dem App-Symbol. Kein Kriterium erfasst diesen Schritt — er läuft bei Bedarf von Hand.
