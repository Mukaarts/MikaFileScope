# B10 · Auslieferung und Signatur — Testbericht

Stand: 2026-08-24 · Geprüft gegen `spec.md` vom 2026-08-23
Prüfumgebung: macOS 14 (arm64), Swift 6.2, `create-dmg` aus Homebrew vorhanden

## Fazit

**Production-ready: nein**

Alle vierzehn Akzeptanzkriterien bestanden — die Skripte tun zuverlässig, was sie sollen:
Bundle zusammensetzen, Sparkle einbetten und von innen nach außen signieren, DMG
gestaltet oder als Rückfallweg erzeugen, sauber abbrechen, wenn Voraussetzungen fehlen.

Was fehlt, ist nicht die Ausführung, sondern die **Vertrauenskette**: Die Auslieferung
ist ad-hoc signiert und nicht notarisiert, Gatekeeper weist sie nachweislich ab, das DMG
trägt überhaupt keine Signatur, und das Binary läuft nur auf Apple silicon, ohne dass
README oder CLAUDE.md das erwähnen. Dazu ein neuer Fund: **Zwei DMGs mit verschiedenem
Inhalt erhalten denselben Dateinamen** — genau der Mechanismus, über den v2.0.0 mit einer
veralteten Feed-Adresse ausgeliefert wurde.

In Verbindung mit BF-06 aus B09 (Installation schlägt fehl) wiegt FB-B10-01 jetzt
schwerer als bei der Erfassung: Die fehlende Notarisierung ist die letzte unwiderlegte
Hypothese für den dortigen Defekt.

| | Anzahl |
|---|---|
| Akzeptanzkriterien geprüft | 14 von 14 |
| davon bestanden | **14** |
| durchgefallen / nicht prüfbar | 0 / 0 |
| Fehlbestand aus der Spec verifiziert | 11 von 11 |
| davon bestätigt | 10 |
| davon **entkräftet** | 1 (FB-B10-10, siehe unten) |
| neue Fehler | 1 (BUG-07, mittel) |

## Akzeptanzkriterien im Einzelnen

| AK | Ergebnis | Nachweis |
|---|---|---|
| AK-01 · Bundle entsteht | ✅ | `Contents/MacOS/MikaFileScope`, `Contents/Info.plist`, `Contents/Resources` alle vorhanden |
| AK-02 · `--clean` leert `.build` | ✅ | Marker-Datei in `.build` angelegt → nach `build.sh --clean` verschwunden; Meldung „Cleaning" erscheint |
| AK-03 · Symbol wird kopiert | ✅ | `Contents/Resources/AppIcon.icns` vorhanden |
| AK-04 · Sparkle eingebettet, rpath gesetzt | ✅ | `Contents/Frameworks/Sparkle.framework` vorhanden; `otool -l` zeigt einen `LC_RPATH` auf `Frameworks` |
| AK-05 · Inside-out signiert | ✅ | `codesign -dv` auf `Autoupdate` und `Sparkle` je `Signature=adhoc` |
| AK-06 · Hardened Runtime + Entitlements | ✅ | `flags=0x10002(adhoc,runtime)`; Entitlements enthalten `app-sandbox` und `disable-library-validation` |
| AK-07 · Abschlussmeldung | ✅ | `==> Build complete: …/build/Mika+FileScope.app (v2.0.0)` plus Prüf- und Startbefehl |
| AK-08 · Signatur verifiziert | ✅ | `codesign --verify --deep --strict` → Exit 0 |
| AK-09 · gestaltetes DMG | ✅ | `create-dmg` erzeugt 2.173.669 Bytes; Abbild enthält `Mika+FileScope.app` **und** `Applications`-Verknüpfung, Volume heißt `Mika+FileScope` |
| AK-10 · Abbruch ohne `create-dmg` | ✅ | Mit reduziertem `PATH`: „ERROR: 'create-dmg' is not installed" plus Homebrew-Anleitung und Verweis auf den Rückfallweg |
| AK-11 · Abbruch ohne Bundle | ✅ | Beide Skripte: „ERROR: App bundle not found … Run 'bash scripts/build.sh' first." |
| AK-12 · Hintergrundbild | ✅ | `installer/dmg-background.png` und `@2x.png` vorhanden und werden verwendet |
| AK-13 · Rückfallweg über `hdiutil` | ✅ | `create-dmg-simple.sh` erzeugt ein Abbild; `hdiutil imageinfo` → `Format: UDZO` |
| AK-14 · Version aus der Info.plist | ✅ | Dateiname `Mika+FileScope-v2.0.0.dmg` entspricht `CFBundleShortVersionString` = 2.0.0 |

## Verifikation des Fehlbestands aus der Spec

| # | Befund | Ergebnis | Beleg |
|---|---|---|---|
| FB-B10-01 | Keine Notarisierung | **bestätigt — hoch** | `Signature=adhoc`; `spctl -a -vv` → `rejected` |
| FB-B10-02 | `disable-library-validation` aktiv | bestätigt — mittel | im Entitlement-Dump enthalten |
| FB-B10-03 | Nur `arm64`, nicht dokumentiert | **bestätigt — hoch** | `lipo -archs` → `arm64` (Sparkle selbst: `x86_64 arm64`); `grep -ci 'apple silicon\|arm64' README.md` → **0 Treffer** |
| FB-B10-04 | CI-Workflow fehlt | bestätigt — mittel | `.github/` existiert nicht; `CLAUDE.md` erwähnt `release.yml` |
| FB-B10-05 | DMG unsigniert | bestätigt — mittel | `codesign -dv` auf dem DMG → „code object is not signed at all" |
| FB-B10-06 | Fehlende Sparkle-Einbettung bricht nicht ab | bestätigt — mittel | `build.sh:55` — `if [ -n "$SPARKLE_FW" ]`, kein `else` |
| FB-B10-07 | `codesign --deep` hebt die Einzelsignaturen auf | **bestätigt — mittel** | In der Reparatur von B09 praktisch belegt: Ein nur mit `--deep` nachsigniertes Bundle startete nicht (`dyld: … different Team IDs`) |
| FB-B10-08 | Keine Versionsverwaltung im Bauvorgang | bestätigt — mittel | kein Skript berührt `CHANGELOG.md` oder die Website |
| FB-B10-09 | Kein Prüfschritt nach dem Bau | bestätigt — niedrig | `codesign --verify` kommt im Skript nur als **Text** vor (`build.sh:88`), wird nie ausgeführt |
| FB-B10-10 | „Keine Bereinigung alter Bauergebnisse" | **entkräftet — siehe unten** | `build.sh` löscht `$APP_BUNDLE` vor jedem Bau |
| FB-B10-11 | `LSApplicationCategoryType` fehlt | bestätigt — niedrig | nicht in der Info.plist |

### FB-B10-10 war falsch rekonstruiert

Die Spec behauptet, `build/` werde „nie geleert". Das trifft nicht zu: `build.sh` entfernt
das Bundle vor jedem Bau (`rm -rf "$APP_BUNDLE"`). Der tatsächliche Mechanismus hinter
dem `Mukaarts`-Vorfall ist ein anderer und wird als **BUG-07** neu erfasst.

Das ist genau der Fall, vor dem der Erfassungs-Skill warnt: Die Spec eines
Bestandsfeatures ist eine Rekonstruktion und kann selbst falsch sein. Korrigiert wird
sie nicht hier — der Eintrag steht in `befunde.md` als entkräftet.

## Fehler

### BUG-07 · Zwei verschiedene Pakete erhalten denselben Dateinamen — mittel

**Betrifft:** AK-14, und als Ursache indirekt BF-02 aus B09
**Reproduktion:**
1. `bash scripts/build.sh` (Bundle trägt jetzt `CFBundleVersion=2` und die korrigierte Feed-Adresse)
2. `bash scripts/create-dmg.sh`
3. Ergebnis: `installer/Mika+FileScope-v2.0.0.dmg`

**Erwartet:** Erkennbar, dass dies ein anderes Paket ist als das ausgelieferte Release.
**Tatsächlich:** Gleicher Name, anderer Inhalt, keine Warnung:

```
neu erzeugt:   2c29e319df5c8d84b0ddaafe…   2.173.669 Bytes
ausgeliefert:  96b439822fc70774789d2d2b…   2.168.264 Bytes
```

Das ausgelieferte Original wurde beim Prüflauf kommentarlos überschrieben und musste aus
einer Sicherung wiederhergestellt werden.

**Warum das zählt:** Der Dateiname folgt allein `CFBundleShortVersionString`. Ein Release
mit gleicher Kurzversion, aber neuer Build-Nummer — genau der Fall, den B09 jetzt
vorsieht — ist am Namen nicht zu unterscheiden. Der `enclosure`-Verweis im `appcast.xml`
zeigt auf diesen Namen; wird unter derselben URL ein anderes Paket abgelegt, passt die
hinterlegte Signatur nicht mehr, und jedes Update scheitert mit „improperly signed".

**Ort:** `scripts/create-dmg.sh:30-31`, `scripts/create-dmg-simple.sh:16-17`
**Vorschlag:** Die Build-Nummer in den Dateinamen aufnehmen
(`Mika+FileScope-v2.0.0-2.dmg`) oder abbrechen, wenn die Zieldatei bereits existiert.

## Sicherheitsprüfung

| Prüfung | Ergebnis | Beleg |
|---|---|---|
| Vertrauenskette der Auslieferung | **BUG/FB-B10-01** | `spctl` → `rejected`; DMG unsigniert |
| Fremde Bibliotheken ladbar | FB-B10-02 | `disable-library-validation` aktiv |
| Geheimnisse in den Skripten | bestanden | kein Schlüssel, kein Token in `scripts/` |
| Manipuliertes Paket unterscheidbar | **BUG-07** | gleicher Name, kein Hash, keine Signatur |
| IDOR, Rate Limits, PII | entfällt | Bauwerkzeuge ohne Nutzerdaten und ohne Server |

## Nächster Schritt

Kein Bauauftrag aus diesem Bericht allein: **BUG-07** und die bestätigten Befunde
FB-B10-01 bis FB-B10-11 gehören sämtlich in die Vorbereitung des nächsten Release und
überschneiden sich mit Feature `01` (Developer-ID, Notarisierung, Sandbox).

```
/sdd-qa B01
```

Die Prüfung läuft in der Risikoreihenfolge weiter. Die Befunde stehen in
`features/befunde.md`; keiner davon ist kritisch, und keiner blockiert die weiteren
Prüfungen — anders als BF-06 aus B09, das an die Notarisierung gekoppelt bleibt.
