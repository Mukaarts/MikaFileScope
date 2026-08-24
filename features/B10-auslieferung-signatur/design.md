# B10 · Auslieferung und Signatur — Systemdesign

Status: `review` · Stand: 2026-08-24 · geprüft, siehe `qa-report.md`

**Kein Code in diesem Dokument.**

## Überblick

Drei Shell-Skripte und zwei Swift-Skripte bilden die gesamte Auslieferung. `build.sh`
übersetzt, setzt das Bundle von Hand zusammen, bettet Sparkle ein und signiert von innen
nach außen. `create-dmg.sh` verpackt das Ergebnis in ein gestaltetes Abbild;
`create-dmg-simple.sh` tut dasselbe ohne Zusatzwerkzeug und ohne Gestaltung.

Was Xcode bei einem App-Target automatisch erledigt — Bundle-Struktur, Plist einsetzen,
Frameworks einbetten, Suchpfade, Signaturreihenfolge —, steht hier als 90 Zeilen Bash.
Das ist der Preis der SPM-Entscheidung und der Grund, warum mehrere Befunde dieses
Features Schritte betreffen, die es in Xcode gar nicht gäbe.

## Ablauf

```
bash scripts/build.sh [--clean]
├── [--clean] rm -rf .build/
├── swift build -c release                      → arm64-Binary (Host-Architektur)
├── Bundle zusammensetzen
│   ├── Contents/MacOS/MikaFileScope            das Programm
│   ├── Contents/Info.plist                     aus Resources/
│   └── Contents/Resources/AppIcon.icns         falls vorhanden
├── Sparkle einbetten                           falls in .build/artifacts gefunden
│   ├── cp -R Sparkle.framework → Contents/Frameworks/
│   ├── install_name_tool -add_rpath @executable_path/../Frameworks
│   └── signieren von innen nach außen:
│       XPCServices/*.xpc → *.app → Autoupdate → Sparkle → Sparkle.framework
└── codesign --force --deep --sign - --options runtime --entitlements …

bash scripts/create-dmg.sh          bash scripts/create-dmg-simple.sh
├── prüft: create-dmg installiert?  ├── prüft: Bundle vorhanden?
├── prüft: Bundle vorhanden?        ├── Version aus Info.plist
├── Version aus Info.plist          └── hdiutil create -format UDZO
├── Hintergrund erzeugen, falls fehlt
└── create-dmg mit Volicon, Hintergrund, 600×400, Drop-Link
```

## Erzeugnisse

| Datei | Wo | Versioniert | Inhalt |
|---|---|---|---|
| `Mika+FileScope.app` | `build/` | nein | das lauffähige Bundle |
| `Mika+FileScope-v<Version>.dmg` | `installer/` | nein | 2.168.264 Bytes bei v2.0.0 — identisch mit dem veröffentlichten Release-Asset |
| `dmg-background.png` / `@2x` | `installer/` | nein | erzeugt aus `GenerateDMGBackground.swift` |
| `AppIcon.icns` / `AppIcon.png` | `Resources/` | **ja** | erzeugt aus `GenerateIcon.swift` |

## Konfiguration

### `Resources/Info.plist` — auslieferungsrelevante Schlüssel

| Schlüssel | Wert | Bedeutung für B10 |
|---|---|---|
| `CFBundleIdentifier` | `lu.daumedia.mikafilescope` | Kennung; für Signatur und Store maßgeblich |
| `CFBundleShortVersionString` | `2.0.0` | bildet den DMG-Dateinamen |
| `CFBundleVersion` | `1` | für B09 entscheidend, hier nur mitgeführt |
| `LSMinimumSystemVersion` | `14.0` | **prüft die macOS-Version, nicht die Architektur** — daraus FB-B10-03 |
| `NSHighResolutionCapable` | `true` | |
| `LSApplicationCategoryType` | *fehlt* | für Feature `01` nachzuholen |

### `Resources/MikaFileScope.entitlements`

| Entitlement | Wert | Folge |
|---|---|---|
| `com.apple.security.app-sandbox` | `false` | Vollzugriff im Rahmen der Nutzerrechte; schließt den App Store aus |
| `com.apple.security.cs.disable-library-validation` | `true` | Erlaubt das Laden fremd signierter Bibliotheken — nötig für die Ad-hoc-Einbettung von Sparkle, zugleich die schwächste Einstellung |

## Vertrauenskette

| Stufe | Soll | Ist | Nachweis |
|---|---|---|---|
| Bundle signiert | Developer ID | **Ad-hoc** | `codesign -dv` → `Signature=adhoc`, `TeamIdentifier=not set` |
| Hardened Runtime | an | **an** | `flags=0x10002(adhoc,runtime)` |
| Notarisiert | ja | **nein** | kein `notarytool` in den Skripten |
| Getackert (`stapler`) | ja | **nein** | — |
| Gatekeeper akzeptiert | ja | **nein** | `spctl -a -vv` → `rejected` |
| DMG signiert | ja | **nein** | kein `codesign` in den DMG-Skripten |

Die Kette bricht bei der ersten Zeile — alles Weitere folgt daraus. Die einzige
Stufe, die trägt, ist der Hardened Runtime, und der nützt ohne gültige Signatur wenig.

## Missbrauchsschutz

| Angriff | Schutz | Lücke |
|---|---|---|
| Manipuliertes DMG untergeschoben | — | **keiner.** Das Abbild ist unsigniert; nur die Herkunft von GitHub Releases bürgt |
| Manipuliertes Bundle im DMG | Ad-hoc-Signatur | Sie belegt nur Unversehrtheit seit dem Signieren, nicht den Urheber |
| Fremde Bibliothek eingeschleust | Hardened Runtime | durch `disable-library-validation` bewusst aufgeweicht |
| Altes, fehlerhaftes Bundle versehentlich veröffentlicht | — | keiner; `build/` wird nie geleert (FB-B10-10, Ursache von FB-B09-03) |

## Externe Abhängigkeiten

| Werkzeug | Wofür | Pflicht |
|---|---|---|
| Swift 6.0 Toolchain | Übersetzen | ja |
| `codesign`, `install_name_tool`, `PlistBuddy`, `hdiutil` | Bundle und Abbild | ja, Teil von macOS |
| `create-dmg` (Homebrew) | gestaltetes DMG | nein — Rückfallweg vorhanden |
| GitHub Releases | Verteilung | ja |

## Erkennbare Entscheidungen

| # | Entscheidung | Alternative | Warum so |
|---|---|---|---|
| 1 | Bundle per Skript statt Xcode-Target | `.xcodeproj` mit App-Target | Hält das Projekt bei reinem SPM. Preis: jeder Schritt, den Xcode automatisch macht, ist hier eine Zeile Bash, die fehlen kann |
| 2 | Ad-hoc-Signatur | Developer ID + Notarisierung | Keine Jahresgebühr. Mit dem Beschluss zum App Store (Feature `01`) fällt dieser Grund weg |
| 3 | Sparkle inside-out signieren | nur `--deep` | Der korrekte Weg — der anschließende `--deep`-Aufruf hebt ihn allerdings teilweise wieder auf (FB-B10-07) |
| 4 | Zwei DMG-Skripte | nur eines | Das gestaltete braucht Homebrew, das einfache nicht. Vernünftig für ein Ein-Personen-Projekt |
| 5 | Version nur in der `Info.plist` | Version in `Package.swift` oder einer eigenen Datei | Eine Quelle — aber ohne Werkzeug, das CHANGELOG und Website mitzieht (FB-B10-08) |
| 6 | CI/CD entfernt | Workflow behalten | **Grund nicht erkennbar.** Commit `8ddde5f` lautet „add via web UI later"; das ist nie geschehen (FB-B10-04) |

## Abdeckung der Akzeptanzkriterien

| AK | Erfüllt durch | Anmerkung |
|---|---|---|
| AK-01 | `build.sh:24-39` | |
| AK-02 | `build.sh:12-21` | |
| AK-03 | `build.sh:36-39` | Symbol optional — fehlt es, entsteht ein Bundle ohne Icon |
| AK-04 | `build.sh:41-53` | |
| AK-05 | `build.sh:54-64` | korrekt umgesetzt |
| AK-06 | `build.sh:76-80` | |
| AK-07 | `build.sh:82-93` | |
| AK-08 | Ergebnis der Signatur | geprüft am 2026-08-23: Exit 0 |
| AK-09 | `create-dmg.sh:46-72` | |
| AK-10 | `create-dmg.sh:12-21` | |
| AK-11 | `create-dmg.sh:23-27`, `create-dmg-simple.sh:10-14` | |
| AK-12 | `create-dmg.sh:34-39` | |
| AK-13 | `create-dmg-simple.sh:24-27` | |
| AK-14 | `PlistBuddy` in beiden Skripten | Rückfallwert `1.0` bei Fehler (EC-05) |


**AK-15, AK-16, AK-17 sind entfallen.** Sie wurden am 2026-08-23 als Fehler eingestuft
und in den *Fehlbestand* der Spec überführt; ihre Nummern bleiben unbesetzt. Was sie
beschrieben, wird von keiner Komponente erfüllt — es ist der Defekt selbst.

**Ohne Zuordnung:** `scripts/GenerateIcon.swift` und `scripts/GenerateDMGBackground.swift`
erzeugen Grafiken und werden von keinem Kriterium erfasst — sie laufen einmalig bzw. bei
Bedarf. `GenerateOGImage.swift` gehört zu B11.
