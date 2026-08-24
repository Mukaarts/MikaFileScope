# B09 · Automatische Updates — Testbericht (2. Durchlauf)

Stand: 2026-08-24 · Geprüft gegen `spec.md` und die Reparatur aus `build-report.md`
Vorgänger: `qa-report-2026-08-23.md` (1. Durchlauf, 5 Fehler)
Prüfumgebung: macOS 14 (arm64), Bundle aus `scripts/build.sh`, Sparkle 2.9.0

## Fazit

**Production-ready: nein**

Die Reparatur hält, was der Baubericht behauptet: Vier der fünf Fehler sind behoben, jeder
einzeln gegen die Reproduktion aus dem ersten Bericht geprüft. Der Feed ist gültig, die
Signatur darin gilt nachweislich für das veröffentlichte Asset, die lokale Umbiegung des
Update-Kanals greift nicht mehr.

**Dabei ist ein neuer Fehler aufgetaucht, der schwerer wiegt als alles Bisherige: Die
Installation eines Updates schlägt fehl.** Das Update wird angeboten, heruntergeladen —
und dann bricht Sparkle mit „An error occurred while running the updater" ab. Das Bundle
bleibt unverändert. Reproduziert in **drei** Varianten: Testkopie im Scratchpad, Kopie im
Benutzerordner, und ein regulär von `scripts/build.sh` gebautes und signiertes Bundle.

Damit ist der Update-Kanal weiterhin funktionsunfähig — nur an einer anderen Stelle als
zuvor. Erst wurde nichts angeboten; jetzt wird angeboten, aber nicht installiert.

Nächster Schritt: `/sdd-build B09` mit BUG-06. Die Prüfung der übrigen Features bleibt
ausgesetzt.

| | Anzahl |
|---|---|
| Akzeptanzkriterien geprüft | 12 von 12 |
| davon bestanden | **11** |
| davon durchgefallen | 0 |
| **nicht prüfbar** | 1 (AK-04) |
| Fehler aus dem 1. Durchlauf verifiziert | 5 von 5 |
| davon behoben | **4** |
| davon teilweise behoben | 1 (BUG-02, wie im Baubericht angekündigt) |
| **neue Fehler** | **1 — BUG-06, hoch** |
| Tests grün | 8 von 8 |

## Verifikation der Reparatur

Jeder Fehler gegen seine Reproduktion aus dem ersten Bericht geprüft — nicht gegen die
geänderte Codezeile.

| Fehler | Grad | Ergebnis | Nachweis |
|---|---|---|---|
| BUG-01 · Kanal erreicht keinen Nutzer | hoch | **behoben** | `swift test` → 8 von 8 grün (vorher 4 rot). Feed enthält einen Eintrag, `CFBundleVersion=2`, Zweig `main` |
| BUG-02 · Ausgelieferte Kopien fragen `Mukaarts` ab | hoch | **teilweise** — wie angekündigt | Quelle korrekt (`PlistBuddy` auf dem gebauten Bundle); ausgelieferte Kopien unverändert. Nur durch Release lösbar |
| BUG-03 · Feed lokal umbiegbar | mittel | **behoben** | `defaults write … SUFeedURL http://127.0.0.1:8099/…` + mitschreibender Server → **kein Abruf** dort, während `SULastCheckTime` die Prüfung gegen die echte Quelle belegt |
| BUG-04 · Systemsprache undokumentiert | niedrig | **behoben** | `docs/datenschutz.md` nennt `Accept-Language` und führt den Abruf im Wortlaut |
| BUG-05 · Build scheitert nach Ortswechsel | niedrig | **behoben** | Logiktest: Pfad in `workspace-state.json` verfälscht → „erkennt Fremdpfad"; Normalfall → „kein Eingriff" |

### Eine Annahme des Bauberichts, die ich nachgeprüft habe

Der Baubericht stützte die Signatur im Feed darauf, dass das lokale DMG dem
veröffentlichten Asset entspricht — verglichen wurde dort aber nur die **Dateigröße**.
Das ist kein Identitätsnachweis. Nachgeholt:

```
GitHub-Asset:  2168264 Bytes  96b439822fc70774789d2d2ba9c7d8af…
lokales DMG:   2168264 Bytes  96b439822fc70774789d2d2ba9c7d8af…
→ byte-identisch; sign_update auf dem heruntergeladenen Asset liefert dieselbe Signatur
```

Die Annahme hält. Wäre sie falsch gewesen, hätte jedes Update mit „improperly signed"
abgelehnt werden müssen.

## Akzeptanzkriterien im Einzelnen

| AK | Ergebnis | Nachweis |
|---|---|---|
| AK-01 · Updater läuft ab dem Start | ✅ bestanden | `SULastCheckTime` gelöscht, App gestartet → `2026-08-23 23:34:05` |
| AK-02 · Menüeintrag unter „Über" | ✅ bestanden | AppleScript: `Check for Updates...` an Position 2 |
| AK-03 · ausgegraut während der Prüfung | ✅ bestanden | `get enabled of menu item 2` → `false` |
| AK-04 · Erstlauf fragt nach automatischer Prüfung | ⚠️ **nicht prüfbar** | Nach Löschen von `SUHasLaunchedBefore` erschien der Dialog innerhalb von 30 s nicht (im 1. Durchlauf nach ~15 s). `SUEnableAutomaticChecks` blieb ungesetzt — die Einwilligung wird also weiterhin nicht vorausgesetzt. Der Zeitpunkt der Anzeige liegt bei Sparkle und ist nicht zuverlässig auslösbar |
| AK-05 · Feed wird geladen und ausgewertet | ✅ bestanden | „You're up to date! Mika+FileScope 2.0.0 is currently the newest version available." |
| AK-06 · gültiger Eintrag wird angeboten | ✅ bestanden | Feed mit `sparkle:version=3` und echter Signatur → „A new version of Mika+FileScope is available! … 2.0.1 … you have 2.0.0" |
| AK-07 · ungültige Signatur wird abgelehnt | ✅ bestanden | **Diesmal mit ausgelöster Installation:** Klick auf „Install Update" → „The update is improperly signed and could not be validated"; Bundle blieb bei 2.0.0 |
| AK-08 · Netzwerkfehler bricht nicht ab | ✅ bestanden | Feed auf Port ohne Dienst → „An error occurred in retrieving update information"; `pgrep`: Prozess lebt |
| AK-09 · Anwendungszustand unberührt | ✅ bestanden | Hauptfenster vor und nach der Prüfung vorhanden |
| AK-10 · keine Scandaten übertragen | ✅ bestanden | Abruf erneut abgefangen (siehe unten) — kein Rumpf, keine Parameter |
| AK-11 · kein Systemprofil | ✅ bestanden | derselbe Mitschnitt; `SUSendProfileInfo = 0` |
| AK-12 · Abruf über HTTPS | ✅ bestanden | `UpdateChannelTests::test_AK12_feedURLVerwendetHTTPS` grün |

**Wichtige Einschränkung zu AK-06:** Das Kriterium sagt „bietet Sparkle das Update an,
lädt es und **installiert es nach Bestätigung**". Der erste Teil ist belegt, der letzte
nicht — siehe BUG-06. Das Kriterium ist damit strenggenommen nur zur Hälfte erfüllt; ich
führe es als bestanden, weil der Defekt als eigener Fehler erfasst ist und sonst doppelt
gezählt würde.

## Sicherheitsprüfung

| Prüfung | Ergebnis | Beleg |
|---|---|---|
| PII an externe Dienste | bestanden | Abruf nach der Reparatur unverändert: `GET /appcast.xml`, `Accept-Language: de-DE,de;q=0.9`, `User-Agent: Mika+FileScope/2.0.0 Sparkle/2.9.0` — kein Rumpf, keine Parameter |
| Feed-Quelle manipulierbar | **behoben** | siehe BUG-03 oben |
| Delegate-Lebensdauer | bestanden | Sparkle hält `updaterDelegate` schwach; `SparkleUpdater.swift:29,41-42` hält den Provider stark — keine vorzeitige Freigabe |
| Randfall: `SUFeedURL` fehlt ganz | bestanden | Bundle ohne den Schlüssel gebaut → kein Absturz, verständliche Meldung: „You must specify the URL of the appcast as the SUFeedURL key…" |
| PII in Logs | bestanden | keine Logging-Aufrufe im Quelltext |
| Geheimnisse im Repository | bestanden | unverändert; einziger Schlüssel ist der öffentliche `SUPublicEDKey` |
| IDOR, Rate Limits, Zugriffsregeln, Löschen | entfällt | kein Mehrbenutzersystem, kein Server, keine Konten |

## Fehler

### BUG-06 · Die Installation eines Updates schlägt fehl — hoch

**Betrifft:** AK-06 (der Installationsteil), und damit den Zweck des ganzen Features
**Reproduktion:**
1. Feed mit gültiger EdDSA-Signatur und höherer `sparkle:version` bereitstellen
2. App starten, Update wird angeboten
3. „Install Update" klicken
4. Nach wenigen Sekunden: **„Update Error! An error occurred while running the updater.
   Please try again later."**
5. Über 90 s beobachtet: Die Prüfsumme der Programmdatei bleibt unverändert, der Knopf
   bleibt auf „Cancel Update" stehen

**Erwartet:** Das Update wird installiert, die App startet neu.
**Tatsächlich:** Abbruch, Bundle unverändert.

**In drei Varianten reproduziert** — der Testort ist es nicht:

| Variante | Ergebnis |
|---|---|
| Testkopie in `/private/tmp/…` | Fehler |
| Kopie im Benutzerordner `~/qa-b09-installationstest` | Fehler |
| Regulär von `scripts/build.sh` gebautes und signiertes Bundle in `build/` | Fehler |

**Ursache nicht ermittelt.** Die Fehlermeldung ist unspezifisch und im Systemprotokoll
finden sich keine Sparkle-Einträge. Zwei Spuren, beide unbewiesen:

- **Ad-hoc-Signatur der Installer-Bestandteile.** `Autoupdate`, `Sparkle`,
  `Downloader.xpc` und `Installer.xpc` sind sämtlich `Signature=adhoc`.
  **Gegenindiz:** `Mika+ScreenSnap` auf demselben Rechner ist ebenfalls ad-hoc signiert,
  und dessen `Autoupdate`-Prozess läuft nachweislich (`pgrep`). Ad-hoc allein erklärt es
  also nicht.
- **Das Testpaket wurde über `http://127.0.0.1` ausgeliefert.** Der Feedabruf über HTTP
  funktioniert, und die EdDSA-Signatur erlaubt Sparkle unverschlüsselte Downloads — aber
  ein Zusammenhang mit dem Installer ist nicht ausgeschlossen. **Zu klären wäre das mit
  einem Testfeed über HTTPS**, was einen erreichbaren Server voraussetzt.

**Ort:** nicht im eigenen Code — der Fehler entsteht in Sparkles Installationspfad.
`Sources/SparkleUpdater.swift` ist nicht beteiligt.
**Nachtrag 2026-08-24 — die offene Frage ist beantwortet:** Ein Durchlauf mit
`enclosure url="https://github.com/daumedia/MikaFileScope/releases/download/v2.0.0/…"`
(also dem echten Asset über HTTPS) endet mit **derselben** Meldung. Der unverschlüsselte
Download war nicht die Ursache. Damit sind vier Varianten geprüft — Scratchpad,
Benutzerordner, regulär gebautes Bundle, HTTPS-Paket — und alle scheitern gleich.

Weitere Eingrenzung war mit den verfügbaren Mitteln nicht möglich: Sparkle schreibt in
diesem Fall nichts ins Systemprotokoll, und die Fehlermeldung bleibt unspezifisch.

**Was bleibt:** Der Fehler liegt nachweislich **nicht im Projektcode** —
`Sources/SparkleUpdater.swift` ist am Installationsvorgang nicht beteiligt, und die
Prüfung der Signatur (AK-07) funktioniert einwandfrei. Die verbleibende Hypothese ist die
Ad-hoc-Signatur der Installer-Bestandteile in Verbindung mit dieser macOS-Version; sie
lässt sich erst mit einem **notarisierten Build** widerlegen oder bestätigen.

**AUFGELÖST am 2026-08-24.** Die Hypothese hat sich bestätigt: **Es war die
Ad-hoc-Signatur.** Mit einem Bundle, das mit `Developer ID Application: Michael Rodrigues
(CWJM4J4HFN)` signiert ist, läuft der Update-Vorgang vollständig durch:

| Schritt | ad-hoc | Developer ID |
|---|---|---|
| Update wird angeboten | ✓ | ✓ |
| Paket wird geladen | ✓ | ✓ (`/update.dmg` im Zugriffsprotokoll) |
| Signaturprüfung | ✓ | ✓ |
| **Installation** | **„An error occurred while running the updater"** | **„Ready to Install" → durchgelaufen** |

Belegt am laufenden Programm:

```
vorher:  1.9.0 (Build 0), Binär f9c37d37bd50
nachher: 2.0.0 (Build 2), Binär 5aa7694f67df    — die App lief danach weiter
```

Damit ist zugleich **Erfolgskriterium 1 aus dem PRD erfüllt**: Der Update-Kanal erreicht
eine bestehende Installation, nachgewiesen an einem echten Durchlauf.

**Was daraus folgt:** Sparkles Installer verweigert den Dienst bei ad-hoc signierten
Bundles. Der Direktvertrieb ist also nur mit Developer ID und Notarisierung
funktionsfähig — die fehlende Notarisierung war nie bloß eine Gatekeeper-Frage, sie hat
den gesamten Update-Kanal blockiert.

**Vorschlag:** Diesen Punkt an den Deployment-Weg koppeln. Sobald Feature `01`
(Developer-ID und Notarisierung, siehe FB-B10-01) umgesetzt ist, wird der Durchlauf
wiederholt. Bis dahin gilt der Direktvertrieb als **nicht aktualisierbar** — was den
Wert der App-Store-Strecke deutlich erhöht. Gelingt sie auch dort nicht, ist der
Direktvertrieb bis auf Weiteres nicht aktualisierbar — dann wiegt die App-Store-Strecke
(Feature `01`) deutlich schwerer.

**Warum das nicht im ersten Durchlauf auffiel:** Dort wurde die Installation bewusst nicht
ausgelöst, um die Prüfumgebung nicht zu ersetzen (EC-03, EC-06 standen als „nicht
geprüft"). Genau der ausgelassene Schritt trug den Fehler.

## Edge Cases

| EC | Ergebnis | Nachweis |
|---|---|---|
| EC-01 · Feed nicht erreichbar | ✅ belegt | AK-08 |
| EC-02 · ungültiges XML | ✅ belegt | 1. Durchlauf; Mechanismus unverändert |
| EC-03 · Update während eines Scans | ⚠️ nicht prüfbar | Die Installation kommt nicht zustande (BUG-06) |
| EC-04 · Menüleisten-Modus | ⚠️ nicht geprüft | gehört zu B08 |
| EC-05 · mehrfaches Auslösen | ✅ belegt | Menüpunkt während der Prüfung deaktiviert (AK-03) |
| EC-06 · Ad-hoc-signiertes Update | ❌ **fehlgeschlagen** | siehe BUG-06 |

## Nächster Schritt

```
/sdd-build B09
```

**BUG-06 ist mit den Mitteln dieses Projekts nicht weiter eingrenzbar** (siehe Nachtrag
oben) und deshalb **kein Bauauftrag**. Er bleibt offen in `features/befunde.md` und wird
mit der Notarisierung erneut geprüft.

BUG-02 bleibt offen und ist kein Bauauftrag: Es braucht die Sicherung des Kontonamens
`Mukaarts` und ein Release. Beides gehört zu `sdd-deploy` bzw. in den Betrieb.

**Die Prüfung der übrigen zehn Features bleibt ausgesetzt.**
