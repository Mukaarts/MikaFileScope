# Befunde — projektweit

Stand: 2026-08-24 (nach der Reparatur) · Quelle: die `qa-report.md` aller elf Features

Diese Liste wird von `sdd-qa` fortgeschrieben. Der Stand unten spiegelt die Reparatur
vom 2026-08-24 (Zweig `fix/b09-update-kanal`, Aufgabenplan `features/01-mac-app-store/tasks.md`).

**Nichts davon ist ausgeliefert.** Behoben heißt: Die Reproduktion aus dem Testbericht
greift nicht mehr, Build und Tests sind grün. Die erneute Prüfung steht aus.

## Behoben am 2026-09-02 — App Review 2026-09-01

Apple hat 2.1.0 abgelehnt. Verifikation: `swift build`, `swift test` (44 Tests) grün,
Store-Bundle gebaut und am laufenden Programm nachgeprüft.

| ID | Feature | Befund | Grad | Wie behoben |
|---|---|---|---|---|
| BF-24 | 01 | **Keine einzige Zweckbeschreibung im Bundle** — die TCC-Dialoge beim Scan des Benutzerordners erschienen ohne Text | hoch | Sechs `NS*UsageDescription` in `Resources/Info.plist`, jede mit Zweck, Beispiel und Grenze · Ablehnungsgrund 5.1.1(ii) |
| BF-25 | 01 | **Export ohne jede Wirkung** — `user-selected.read-only` verhindert, dass die Powerbox den Speichern-Dialog überhaupt öffnet | hoch | `read-write`; gegengeprüft mit beiden Signaturen an derselben App · Ablehnungsgrund 2.1(a) |
| BF-26 | B07 | Speichern-Dialog per `runModal()` aus einer SwiftUI-`Menu`-Aktion | mittel | Als Blatt am Fenster, Rückfall auf `runModal()` ohne Fenster · schließt AS-06 |
| BF-27 | B08 | Duplikatsuche las ohne Security Scope; nach einem Neustart meldete sie „keine Duplikate", statt zu sagen, dass sie nichts öffnen konnte | hoch | `detect(urls:scopeRoot:)` hält den Scope; nicht lesbare Dateien werden gezählt und benannt |
| BF-28 | B01 | Scan-Fortschritt stand still — `performScan` ist `nonisolated` und erreichte `scannedSoFar` nie | mittel | Fortschritt über einen `AsyncStream`, Muster aus `DuplicateDetector` |
| BF-29 | B01/B08 | „Cancel" beendete nur die Anzeige: ein `Task.detached` erbt den Abbruch seines Erzeugers nicht | mittel | Der Hintergrundlauf wird eigens festgehalten und mit abgebrochen |
| BF-30 | B05 | Deutsche Textfragmente in der englischen Oberfläche (AS-08) | mittel | Durchgehend englisch — Fortschritt, Menü, Duplikatblatt, Beschriftungen |
| BF-31 | 01 | Kein Hinweis vor den Systemabfragen; verweigerter Zugriff blieb stumm | mittel | `AccessIntroView` vor dem ersten Zugriff; Meldungen nennen die Systemeinstellungen |

## Offen — und warum sie offen bleiben

Zwei Befunde brauchen noch eine Handlung, die nur der Betreiber vornehmen kann.

| ID | Feature | Befund | Grad | Was fehlt |
|---|---|---|---|---|
| BF-02 | B09 | Ausgelieferte Kopien fragen `Mukaarts` ab | hoch → **entschärft** | Der Feed auf `master` ist gepflegt und live nachgeprüft; ein künftiges Release erreicht die Altbestände. Bleibt: **den Kontonamen registrieren**, damit die Weiterleitung nicht in fremde Hand fällt |
| BF-10 | B11 | Impressum unvollständig | hoch → **teilweise** | `imprint.html` steht unter `/imprint`; drei Platzhalter (Anschrift, RCS-Nummer, USt-IdNr.) sind nur vom Betreiber zu füllen |
| BF-11 | B10 | Keine Notarisierung | hoch → **teilweise** | Developer ID ist vorhanden und wird von `build.sh --release` verwendet. Es fehlt nur das Zugangsprofil: `xcrun notarytool store-credentials` — danach erledigt `scripts/notarize.sh` den Rest |

## Behoben am 2026-08-24

Alle mit Verifikation: `swift build` und `swift test` grün, beide Bauvarianten.

| ID | Feature | Befund | Grad | Wie behoben |
|---|---|---|---|---|
| BF-06 | B09 | **Installation eines Updates schlug fehl** | hoch | **Ursache geklärt: die Ad-hoc-Signatur.** Mit Developer ID läuft der Vorgang durch — belegt an einem echten Durchlauf von 1.9.0 (Build 0) auf 2.0.0 (Build 2) |
| BF-01 | B09 | Update-Kanal erreichte keinen Nutzer | hoch | `appcast.xml` mit signiertem Eintrag, `CFBundleVersion` 2, Feed auf `main` — **gepusht**, live nachgeprüft |
| BF-12 | B10 | Nur `arm64`, nicht dokumentiert | hoch | `build.sh --universal` baut `x86_64 arm64`; README nennt die Anforderung |
| BF-03 | B09 | Feed lokal umbiegbar | mittel | `FeedURLProvider` liefert die Adresse aus der signierten Info.plist |
| BF-07 | B10 | Zwei Pakete, ein Dateiname | mittel | Build-Nummer im DMG-Namen; Warnung, wenn eine Datei ersetzt wird |
| BF-13 | B03/B06/B08 | Filter wirkte nur auf drei von fünf Ansichten | mittel | Duplikatsuche und Menüleiste lesen die gefilterten Felder. **B05 bleibt bewusste Ausnahme** — die Zeitfenster werden beim Scan verdichtet |
| BF-14 | B06 | 1-KB-Schwelle unsichtbar | mittel | Übersprungene Dateien werden gezählt und im Blatt benannt |
| BF-15 | B01/B06 | Kein Abbruch, kein Fortschritt | mittel | Abbruchknopf für beide Vorgänge; echter Prozentwert in der Duplikatsuche |
| BF-16 | B01 | Gleichzeitige Scans | mittel | Ein laufender Durchlauf wird abgebrochen, bevor ein neuer beginnt |
| BF-17 | B01/B06 | Zählweise folgte dem Enumerator | mittel | `.skipsPackageDescendants`, Symlinks übersprungen, Hardlinks über die Inode erkannt |
| BF-18 | B02/B04 | Keine Barrierefreiheit | mittel | Beschriftungen für Kennzahlen, Tabellenspalten, beide Diagramme und die Zeitachse |
| BF-19 | B08 | Menüleiste ohne Ordnerwahl | mittel | Eintrag „Ordner…" in der Fußzeile des Popovers |
| BF-20 | B11 | Version an vier Stellen von Hand | mittel | `scripts/update-website-version.sh` setzt alle vier aus der Info.plist |
| BF-21 | B10 | CI beschrieben, nicht vorhanden | mittel | `.github/workflows/ci.yml` und `release.yml`; die CI prüft eigens, dass die Store-Variante kein Sparkle enthält |
| BF-22 | B11 | „Open source" ohne Lizenz | mittel | `LICENSE` (Source Available); Website und README richtiggestellt |
| BF-23 | alle | Nur ein Feature hatte Tests | mittel | **28 Tests** über Update-Kanal, Kategorien, Zeitfenster, beide Exporter und das Datenmodell |
| BF-04 | B09 | `Accept-Language` undokumentiert | niedrig | in `docs/datenschutz.md` und der Datenschutzerklärung genannt |
| BF-05 | B09 | Build scheiterte nach Ortswechsel | niedrig | `build.sh` erkennt einen Cache mit fremdem Pfad und räumt auf |

### Niedrige Befunde, mitbehoben

| Ursprung | Behoben |
|---|---|
| B07 · BUG-09 | Prozentwerte als Dezimalzahl — keine 16 Nachkommastellen mehr |
| B07 · FB-B07-01 | Fehlgeschlagener JSON-Export meldet den Fehler statt `{}` zu schreiben |
| B07 · FB-B07-04 | `scannedAt` ist der Scanzeitpunkt |
| B01 · FB-B01-06 | `reset()` an *Zurücksetzen* (Cmd-Shift-K) gebunden |
| B01 · FB-B01-01/07 | Security-Scoped Bookmark: „Rescan" überlebt den Neustart |
| B01 · AK-20 | Lesefehler werden gezählt und in der Oberfläche gemeldet |
| B03 · FB-B03-02/03/04 | `allKnownExtensions` einmalig; `.ts` nur bei Videos; Filter beim Ordnerwechsel zurückgesetzt |
| B02 · FB-B02-01/02 | Farbzuordnung ohne quadratischen Aufwand; Anteilsspalte sortierbar |
| B02/B04 · FB-B02-04, FB-B04-03 | Grau bedeutet nur noch „Other"; die Palette rotiert darüber hinaus weiter |
| B04/B05 · DS-01, DS-03, FB-B05-05 | Palette beginnt bei der Markenfarbe; der Alterverlauf kommt aus derselben Quelle |
| B05 · FB-B05-03 | Ein Bezugszeitpunkt je Durchlauf statt je Datei |
| B08 · FB-B08-03 | `showMenubar` als Konstante statt dreimal als Zeichenkette |
| B10 · FB-B10-07/09 | `codesign --deep` entfernt; Signaturprüfung läuft jetzt tatsächlich |
| B10 · FB-B10-06/11 | Fehlendes Sparkle bricht den Bau ab; `LSApplicationCategoryType` gesetzt |
| B11 · FB-B11-06/07 | `lastmod` aktuell; Content-Security-Policy gesetzt |

## Widerlegt

Befunde aus der Rückerfassung, die die Prüfung **nicht** bestätigt hat. Sie stehen hier,
weil eine stillschweigend gestrichene Vermutung genauso irreführend ist wie eine
stehengelassene falsche.

| Ursprung | Behauptung | Prüfergebnis |
|---|---|---|
| B10 · FB-B10-10 | „`build/` wird nie geleert" | **falsch.** `build.sh` entfernt das Bundle vor jedem Bau. Der tatsächliche Mechanismus hinter dem `Mukaarts`-Vorfall ist BF-07 |
| B01 · Symlink-Befund | „Der Inhalt kann doppelt in der Statistik auftauchen" | **zu scharf.** Der Symlink zählt in der Anzahl, trägt zur Größe aber nur 8 Byte bei (Länge des Zielpfads). Belegt: `.PDF, 3, 65008` |
| B07 · FB-B07-03 | „Gemischte Zahlenformate in der CSV" | **nicht reproduzierbar** auf dem Prüfrechner: `ByteCountFormatter` liefert `10 KB`, `400 bytes` in englischer Schreibweise. Gilt nur bei abweichender Regionseinstellung |

## Muster

Was in mehr als einem Feature auftritt — der Grund, warum diese Liste existiert.

- **Der Bestand ist nicht falsch programmiert, sondern nie erprobt.** Über alle elf
  Features hinweg bestehen die Kriterien fast durchgängig; von 145 geprüften Kriterien
  ist genau **eines** durchgefallen (AK-13 in B07). Die schweren Befunde liegen ohne
  Ausnahme außerhalb der Programmlogik: in Daten (leerer Feed), Konfiguration
  (Build-Nummer, Zweig), Auslieferung (Signatur, Architektur) und in dem, was **fehlt**
  (Impressum, Tests, Notarisierung).
- **Was nicht ausgeführt wird, gilt als in Ordnung.** BF-06 blieb im ersten Durchlauf
  verborgen, weil die Installation bewusst nicht ausgelöst wurde. Genau der ausgelassene
  Schritt trug den Fehler. Dasselbe Muster droht bei jedem der 23 Kriterien, die in
  diesen Berichten als *nicht prüfbar* stehen.
- **Der Filter ist an vier Stellen halb umgesetzt** (BF-13) — ein Entwurf, der richtig
  gedacht und dreimal nicht zu Ende geführt wurde. Bei B05 ist die Ursache tiefer als
  bei B06 und B08: dort verhindert das Datenmodell die Filterung.
- **Barrierefreiheit fehlt durchgängig** (BF-18). Die Prüfung selbst hat es belegt: Die
  Werte der Kennzahlen sind auslesbar, die Diagramme und Balken nicht, und die
  Spaltenköpfe der Tabelle lassen sich nicht bedienen.
- **Dokumentation und Wirklichkeit laufen auseinander** — CI-Workflow beschrieben aber
  nicht vorhanden (BF-21), CHANGELOG seit v1.0.0 nicht fortgeschrieben, Palette laut
  `CLAUDE.md` synchron und tatsächlich nicht, Sparkle-Version veraltet angegeben,
  Architektur nirgends erwähnt (BF-12).
