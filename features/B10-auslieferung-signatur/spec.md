# B10 · Auslieferung und Signatur — Spezifikation

Status: `review` · Stand: 2026-08-24 · geprüft, siehe `qa-report.md`

> Beschrieben ist, was der Bestand am 2026-08-23 tut — nicht, was er tun sollte.
> **Alle Kriterien in diesem Dokument beschreiben Verhalten, das so gewollt ist.**
> Was fragwürdig war, wurde am 2026-08-23 entschieden und steht im *Fehlbestand*.

## Zweck

Aus dem Quelltext wird eine startfähige, signierte `.app` und daraus ein DMG, das
Nutzer herunterladen und in ihren Programme-Ordner ziehen. B10 bestimmt, was die
Nutzer überhaupt in die Hand bekommen — und ob macOS es startet.

## Abhängigkeiten

| Braucht | Status | Warum |
|---|---|---|
| B09 · Automatische Updates | `rekonstruiert` | Das Bundle muss Sparkle einbetten und mitsignieren; ohne B10 hat B09 nichts auszuliefern |

## User Stories

- **US-01** · Als Entwickler möchte ich mit einem Befehl ein fertiges App-Bundle
  erzeugen, damit ein Release keine Handarbeit ist.
- **US-02** · Als Nutzer möchte ich ein DMG herunterladen, es öffnen und die App in
  „Programme" ziehen — der auf macOS gewohnte Weg.
- **US-03** · Als Nutzer möchte ich, dass macOS die App ohne Warnung startet, damit ich
  ihr vertrauen kann.

## Nicht im Scope

- **Der Update-Mechanismus selbst** — B09.
- **Die Download-Seite** — B11.
- **Store-Signatur und Einreichung** — Feature `01`.

## Akzeptanzkriterien

### Bundle bauen · `scripts/build.sh`

- **AK-01** · Angenommen, das Projekt liegt vor, wenn `bash scripts/build.sh` läuft,
  dann entsteht `build/Mika+FileScope.app` mit `Contents/MacOS`, `Contents/Resources`
  und `Contents/Info.plist`.
- **AK-02** · Angenommen, `--clean` wird übergeben, wenn das Skript startet, dann wird
  `.build/` zuvor vollständig gelöscht.
- **AK-03** · Angenommen, `Resources/AppIcon.icns` existiert, wenn das Bundle
  zusammengesetzt wird, dann liegt das Symbol in `Contents/Resources/AppIcon.icns`.
- **AK-04** · Angenommen, Sparkle wurde von SwiftPM heruntergeladen, wenn das Skript
  läuft, dann findet es `Sparkle.framework` unter `.build/artifacts`, kopiert es nach
  `Contents/Frameworks/` und ergänzt den Suchpfad `@executable_path/../Frameworks`.
- **AK-05** · Angenommen, Sparkle ist eingebettet, wenn signiert wird, dann werden die
  verschachtelten Bestandteile **von innen nach außen** signiert: erst die
  XPC-Dienste, dann die enthaltenen `.app`-Bündel, dann `Autoupdate`, dann das
  Framework selbst, zuletzt das App-Bundle.
- **AK-06** · Angenommen, das Bundle ist fertig, wenn es signiert wird, dann geschieht
  das mit **Hardened Runtime** und den Entitlements aus
  `Resources/MikaFileScope.entitlements`.
- **AK-07** · Angenommen, der Bau ist abgeschlossen, wenn das Skript endet, dann meldet
  es den Pfad, die Version aus der `Info.plist` und die Befehle zum Prüfen und Starten.
- **AK-08** · Angenommen, das fertige Bundle wird geprüft, wenn
  `codesign --verify --deep --strict` läuft, dann meldet es keinen Fehler.

### DMG erzeugen

- **AK-09** · Angenommen, `create-dmg` ist installiert und das Bundle existiert, wenn
  `bash scripts/create-dmg.sh` läuft, dann entsteht
  `installer/Mika+FileScope-v<Version>.dmg` mit Hintergrundbild, Volume-Symbol,
  Fenstergröße 600 × 400 und einer Verknüpfung auf „Programme".
- **AK-10** · Angenommen, `create-dmg` fehlt, wenn das Skript startet, dann bricht es
  mit einer Anleitung ab und verweist auf `create-dmg-simple.sh`.
- **AK-11** · Angenommen, das App-Bundle fehlt, wenn eines der DMG-Skripte startet, dann
  bricht es mit dem Hinweis ab, zuerst `build.sh` auszuführen.
- **AK-12** · Angenommen, das Hintergrundbild fehlt, wenn `create-dmg.sh` läuft, dann
  erzeugt es dieses zuvor über `swift scripts/GenerateDMGBackground.swift`.
- **AK-13** · Angenommen, keine Zusatzwerkzeuge sind vorhanden, wenn
  `bash scripts/create-dmg-simple.sh` läuft, dann entsteht über `hdiutil` ein
  komprimiertes DMG (UDZO) ohne Gestaltung.
- **AK-14** · Angenommen, ein DMG wird erzeugt, wenn der Dateiname gebildet wird, dann
  stammt die Versionsnummer aus der `Info.plist` des **gebauten Bundles**, nicht aus
  einer getrennten Angabe.

### Zu Fehlern erklärt — nicht mehr als Kriterium geführt

Die Nummern **AK-15, AK-16, AK-17** beschrieben Verhalten, das der Code tatsächlich zeigt, und
waren als ⚠-Kriterien aufgenommen. Am 2026-08-23 wurden sie als **Fehler** eingestuft und
in den *Fehlbestand* überführt. Die Nummern bleiben unbesetzt, damit Verweise aus
`design.md` und aus späteren Berichten eindeutig bleiben.

**Für `sdd-qa` heißt das:** keine zu bestätigenden Kriterien, sondern eine Suchliste.

## Edge Cases

- **EC-01** · `swift build -c release` schlägt fehl → `set -euo pipefail` bricht sofort
  ab, kein halbfertiges Bundle bleibt zurück.
- **EC-02** · Sparkle nicht in `.build/artifacts` gefunden → das Skript **überspringt
  die Einbettung stillschweigend** und baut ein Bundle ohne Update-Fähigkeit.
- **EC-03** · `install_name_tool` schlägt fehl → wird mit `|| true` verschluckt; das
  Bundle entsteht, findet aber Sparkle zur Laufzeit nicht.
- **EC-04** · Ein DMG gleichen Namens liegt bereits vor → wird vor dem Erzeugen gelöscht.
- **EC-05** · Version nicht aus der `Info.plist` lesbar → beide DMG-Skripte fallen auf
  die Zeichenkette `1.0` zurück und erzeugen ein falsch benanntes Paket.

## Fehlbestand

- **FB-B10-01 · Keine Notarisierung, nur Ad-hoc-Signatur.** `scripts/build.sh:76-80`
  signiert mit `--sign -`; kein `notarytool`, kein `stapler`, keine Developer-ID.
  Nachgewiesen mit `spctl -a -vv` → `rejected`. Folge: Jeder Nutzer sieht beim ersten
  Start eine Blockade und muss sie umgehen — genau die Handlung, die man Nutzern
  eigentlich abgewöhnen will.

- **FB-B10-02 · `disable-library-validation` ist aktiviert.**
  `Resources/MikaFileScope.entitlements:7-8`. Folge: Die App darf fremde, nicht von
  derselben Instanz signierte Bibliotheken laden. Für die Ad-hoc-Einbettung von Sparkle
  praktisch, sicherheitstechnisch die schwächste Einstellung — und für den App Store
  (Feature `01`) unzulässig.

- **FB-B10-03 · Nur `arm64`, ohne dass es dokumentiert wäre.** `lipo -archs` liefert
  `arm64`; `swift build -c release` erzeugt grundsätzlich nur die Architektur des
  bauenden Rechners. `README.md` und `CLAUDE.md` nennen die Einschränkung nicht.
  Folge: Ein Intel-Nutzer mit unterstütztem macOS lädt ein Paket, das nicht startet.

- **FB-B10-04 · Der CI/CD-Workflow existiert nicht.** `CLAUDE.md:50` und `README.md`
  beschreiben `.github/workflows/release.yml`; das Verzeichnis `.github/` fehlt
  vollständig (entfernt in Commit `8ddde5f`). Folge: Releases entstehen ausschließlich
  von Hand auf einem einzelnen Rechner; die Dokumentation behauptet Automatisierung,
  die es nicht gibt.

- **FB-B10-05 · Das DMG wird nicht signiert.** Weder `create-dmg.sh` noch
  `create-dmg-simple.sh` rufen `codesign` auf das fertige Abbild auf. Folge: Ein
  manipuliertes DMG ist von einem echten nicht zu unterscheiden.

- **FB-B10-06 · Fehlende Sparkle-Einbettung schlägt nicht fehl.** `build.sh:46` prüft
  mit `if [ -n "$SPARKLE_FW" ]` und überspringt den Block sonst kommentarlos. Folge: Ein
  Bundle ohne Update-Fähigkeit sieht von außen aus wie ein vollständiges.

- **FB-B10-07 · `codesign --deep` wird verwendet.** `build.sh:77`. Apple rät seit Jahren
  davon ab, weil verschachtelte Bestandteile dabei erneut und ohne ihre eigenen
  Entitlements signiert werden. Das Skript signiert Sparkle vorher korrekt von innen
  nach außen — und überschreibt das anschließend mit `--deep`.

- **FB-B10-08 · Keine Versionsverwaltung im Bauvorgang.** Version wird nur in
  `Resources/Info.plist` gepflegt, `CFBundleVersion` bleibt auf `1` (siehe FB-B09-02).
  Folge: `CHANGELOG.md`, Website und Bundle können auseinanderlaufen — und tun es
  bereits.

- **FB-B10-09 · Kein Prüfschritt nach dem Bau.** Das Skript nennt
  `codesign --verify` in der Ausgabe, führt es aber nicht aus. Folge: Ein fehlerhaft
  signiertes Bundle fällt erst beim Nutzer auf.

- **FB-B10-10 · Keine Bereinigung alter Bauergebnisse.** `build/` und `installer/` sind
  in `.gitignore`, werden aber nie geleert. Folge: Ein altes Bundle — wie das mit der
  `Mukaarts`-Feed-URL — bleibt liegen und kann versehentlich veröffentlicht werden.
  Genau daraus entstand FB-B09-03.

- **FB-B10-11 · `LSApplicationCategoryType` fehlt.** Für den App Store (Feature `01`)
  Pflicht, ausserdem bestimmt der Wert die Einordnung im Finder. Folge: heute
  unauffällig, für `01` nachzuholen.

### Aus Kriterien zu Fehlern erklärt (2026-08-23)

- **war AK-15** · Angenommen, ein Nutzer lädt das DMG herunter und startet die App per
  Doppelklick, wenn Gatekeeper prüft, dann **verweigert macOS den Start**.
  *(Nachgewiesen: `spctl -a -vv build/Mika+FileScope.app` → `rejected`. Die Signatur ist
  Ad-hoc (`Signature=adhoc`, `TeamIdentifier=not set`), eine Notarisierung findet
  nirgends statt. Der Nutzer muss den Umweg über Rechtsklick → Öffnen gehen; die
  Website erklärt das auch. Am 2026-08-23 als Fehler eingestuft.)*

- **war AK-16** · Angenommen, ein Intel-Mac mit macOS 14 lädt die App, wenn sie gestartet
  wird, dann **läuft sie nicht** — das Programm enthält nur `arm64`.
  *(Nachgewiesen: `lipo -archs` liefert `arm64`, während das eingebettete
  Sparkle-Framework `x86_64 arm64` enthält. `README.md` und `CLAUDE.md` nennen als
  Anforderung nur „macOS 14.0+", obwohl Sonoma auf Intel-Macs läuft. Nur die Website
  nennt „Apple silicon". Am 2026-08-23 als Fehler eingestuft.)*

- **war AK-17** · Angenommen, ein Release wird erstellt, wenn die Version festgelegt wird,
  dann geschieht das **von Hand** in `Resources/Info.plist` — kein Skript zählt hoch,
  kein Skript prüft die Übereinstimmung mit `CHANGELOG.md` oder der Website.
  *(Folge sichtbar: `CHANGELOG.md` führt alle Funktionen ab 1.0.0 unter `[Unreleased]`,
  obwohl v2.0.0 seit dem 2026-03-23 veröffentlicht ist. Am 2026-08-23 als Fehler eingestuft.)*

## Offene Fragen

- **OF-01** · ~~Soll ein universelles Binary gebaut werden?~~
  **Ja, entschieden und umgesetzt am 2026-08-24.** `bash scripts/build.sh --universal` erzeugt `x86_64 arm64`. Die Website nennt jetzt beide Architekturen.
- **OF-02** · ~~*(eingetragen am 2026-08-24 aus der Reparatur von B09, nicht mitgebaut.)* Beim Bau einer Prüfkopie zeigte sich: Ein ad-h~~
  **Ja, entfernt am 2026-08-24.** `scripts/build.sh` signiert ohne `--deep`; die verschachtelten Bestandteile werden weiterhin einzeln von innen nach außen signiert. Beide Bauvarianten bestehen `codesign --verify --strict`.

## Decision Log

| # | Frage | Entscheidung | Begründung |
|---|---|---|---|
| 1 | Xcode-Projekt oder SPM? | SPM, kein `.xcodeproj` | Ein `Package.swift` genügt; der Bundle-Bau wird von einem Skript übernommen. Preis: alles, was Xcode sonst automatisch tut, steht in `build.sh` |
| 2 | Wie wird signiert? | Ad-hoc (`--sign -`) | Kein Apple Developer Program nötig, keine Jahresgebühr. Preis: Gatekeeper blockiert den ersten Start (FB-B10-01) |
| 3 | Wie entsteht das DMG? | `create-dmg` mit Rückfallweg über `hdiutil` | Gestaltetes Abbild, wenn das Werkzeug da ist; sonst wenigstens ein funktionierendes |
| 4 | Wo liegt das Ergebnis? | `build/` und `installer/`, beide gitignored | Bauergebnisse gehören nicht ins Repository. Preis: keine Bereinigung, alte Stände bleiben liegen (FB-B10-10) |
| — | Sind die ⚠-Kriterien gewolltes Verhalten? | **Nein, 3 davon sind Fehler** (2026-08-23) | Gebündelt entschieden über alle Features hinweg; die Muster stehen in `features/index.md` |
