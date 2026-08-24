# B11 · Marketing-Website — Testbericht

Stand: 2026-08-24 · Geprüft gegen `spec.md` vom 2026-08-23
Prüfung **live gegen https://filescope.daumedia.lu**, nicht gegen die lokalen Dateien

## Fazit

**Production-ready: nein**

Technisch ist die Seite die sauberste Komponente des Projekts: Alle vier zugesagten
Sicherheitskopfzeilen sind live gesetzt — plus HSTS, das die Spec gar nicht nennt —, der
Langzeit-Cache greift, robots.txt und Sitemap sind erreichbar, die Seite antwortet mit
HTTP 200.

Nicht production-ready ist sie aus **rechtlichen** Gründen: Unter einer `.lu`-Domain
betrieben, fehlen Impressum und Datenschutzerklärung vollständig — fünf geprüfte Pfade
antworten mit 404. Dazu steht auf derselben Seite zweimal „Open source" und einmal
„All rights reserved".

| | Anzahl |
|---|---|
| Akzeptanzkriterien geprüft | 17 von 17 |
| davon bestanden | **13** |
| nicht prüfbar | 4 (JS-Interaktion, siehe unten) |
| Fehlbestand verifiziert | 8 von 8, alle bestätigt |

## Akzeptanzkriterien im Einzelnen

| AK | Ergebnis | Nachweis |
|---|---|---|
| AK-01 · fünf Abschnitte | ✅ | `index.html` enthält `#top`, `#features`, `#screenshots`, `#how`, `#install` |
| AK-02 · kein Build-Schritt | ✅ | `vercel.json` ohne `buildCommand`; Auslieferung 1:1 |
| AK-03 · Sicherheitskopfzeilen | ✅ | Live: `x-content-type-options: nosniff`, `referrer-policy: strict-origin-when-cross-origin`, `x-frame-options: SAMEORIGIN`, `permissions-policy: geolocation=(), microphone=(), camera=(), interest-cohort=()` — **zusätzlich** `strict-transport-security: max-age=63072000` |
| AK-04 · Cache für Assets | ✅ | Live: `cache-control: public, max-age=31536000, immutable` |
| AK-05 · Datenschutz-Zusagen | ✅ | Abschnitt vorhanden; inhaltlich durch B09 belegt (kein Netzwerkcode) |
| AK-06 · „löscht nichts" | ✅ | Aussage vorhanden; durch B06 am Programm bestätigt |
| AK-07 · Systemvoraussetzungen | ✅ | „macOS 14 Sonoma or later · Apple silicon" — die Architekturangabe stimmt (`lipo` → `arm64`) |
| AK-08 · Gatekeeper-Hinweis | ✅ | Abschnitt „First launch takes one extra click"; durch `spctl` → `rejected` bestätigt |
| AK-09 · echte Bildschirmfotos | ✅ | `assets/shots/*.webp`, Dark Mode — deckt sich mit den Aufnahmen aus dieser Prüfung |
| AK-10 · Kopfleiste bei Scroll | ⚠️ nicht prüfbar | Erfordert einen Browser mit JS; nur die Quelle wurde gelesen |
| AK-11 · Reiter-Umschaltung | ⚠️ nicht prüfbar | dito |
| AK-12 · Tastaturbedienung der Reiter | ⚠️ nicht prüfbar | dito |
| AK-13 · Kopierschaltfläche | ⚠️ nicht prüfbar | dito |
| AK-14 · funktioniert ohne JS | ✅ | Aufbau belegt: `hidden` wird nur per JS gesetzt, Grundzustand sichtbar; `curl` liefert vollständigen Inhalt ohne Skriptausführung |
| AK-15 · Skip-Link | ✅ | `<a class="skip-link" href="#main">` im ausgelieferten HTML |
| AK-16 · Metadaten und JSON-LD | ✅ | Live: `"softwareVersion": "2.0.0"`, Canonical, OG- und Twitter-Angaben vorhanden |
| AK-17 · robots.txt | ✅ | Live abrufbar, `Allow: /`, Sitemap verlinkt; `sitemap.xml` → HTTP 200 |

## Verifikation des Fehlbestands

| # | Befund | Ergebnis | Beleg (live) |
|---|---|---|---|
| FB-B11-01 | Keine Datenschutzerklärung, kein Impressum | **bestätigt — hoch** | `/privacy`, `/imprint`, `/impressum`, `/datenschutz`, `/legal` → **alle HTTP 404** |
| FB-B11-02 | „Open source" ohne Lizenz | **bestätigt — mittel** | Auf derselben Seite: 2× „Open source", 1× „All rights reserved"; keine `LICENSE` im Repository |
| FB-B11-03 | Version, Größe, Link fest verdrahtet | **bestätigt — mittel** | Live: „Version 2.0.0", „2.1 MB", `v2.0.0.dmg`, JSON-LD `2.0.0` — vier Stellen |
| FB-B11-04 | Filterzusage unvollständig | bestätigt — mittel | Zeitachse und Duplikatsuche folgen dem Filter nicht (in B03/B05 belegt) |
| FB-B11-05 | Palette weicht von der App ab | bestätigt — niedrig | `--text: #E8F3EE` gegenüber `textPrimary #E1F5EE`; `--muted` ohne Entsprechung |
| FB-B11-06 | `lastmod` veraltet | **bestätigt — niedrig** | Live `<lastmod>2026-07-30`; letzte Änderung an `website/` war 2026-08-01 |
| FB-B11-07 | Keine Content-Security-Policy | **bestätigt — niedrig** | Keine `content-security-policy` in den Antwortkopfzeilen |
| FB-B11-08 | Kein Abgleich zwischen Zusage und Code | bestätigt — mittel | `website/README.md` nennt drei Prüfbefehle; keiner läuft automatisch |

**Bemerkenswert:** Zwei Aussagen der Seite, die man leicht anzweifeln würde, halten der
Prüfung stand — „Apple silicon" und der Gatekeeper-Hinweis sind beide korrekt und
belegen, dass die Seite an diesen Stellen ehrlicher ist als die `README.md`, die die
Architektur gar nicht erwähnt.

## Sicherheitsprüfung

| Prüfung | Ergebnis | Beleg |
|---|---|---|
| Transportsicherheit | bestanden | HTTPS mit HSTS `max-age=63072000` |
| MIME-Verwechslung | bestanden | `nosniff` live gesetzt |
| Einbettung in fremde Seiten | bestanden | `x-frame-options: SAMEORIGIN` |
| Fremde Skripte / CSP | FB-B11-07 | keine CSP; die Seite bindet allerdings keine externen Quellen ein |
| Cookies, Tracker | bestanden | keine `set-cookie`-Kopfzeile, keine Analytik im Quelltext |
| Rechtliche Pflichtangaben | **FB-B11-01** | fünf Pfade, fünfmal 404 |

## Nächster Schritt

Kein Bauauftrag im Sinne von Code. **FB-B11-01** ist der dringendste Punkt des ganzen
Projekts außerhalb von B09: Eine gewerblich betriebene Seite unter einer EU-Domain ohne
Anbieterkennzeichnung und ohne Datenschutzerklärung ist ein rechtliches Risiko — und für
den beschlossenen App-Store-Weg (Feature `01`) ohnehin eine Voraussetzung.

```
/sdd-qa B03
```
