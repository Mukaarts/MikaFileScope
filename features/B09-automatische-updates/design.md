# B09 · Automatische Updates — Systemdesign

Status: `review` · Stand: 2026-08-24 · geprüft, siehe `qa-report.md`

**Kein Code in diesem Dokument.** Beschrieben ist der Aufbau, wie er ist — nicht, wie er
sein sollte.

## Überblick

Die App bindet Sparkle 2.9.0 als Swift-Package ein und kapselt es in einer einzigen
Klasse mit 37 Zeilen. Beim Start erzeugt der `AppDelegate` diese Klasse, die ihrerseits
einen `SPUStandardUpdaterController` mit `startingUpdater: true` anlegt — der Updater
läuft damit ab dem ersten Moment, ohne Zutun des Nutzers.

Wo geprüft wird, steht nicht im Code, sondern in der `Info.plist`: `SUFeedURL` nennt eine
XML-Datei auf GitHub, `SUPublicEDKey` den öffentlichen Schlüssel, gegen den jede
Aktualisierung geprüft wird. Die gesamte Bedienung besteht aus einem Menüeintrag; alles
Weitere — Dialoge, Fortschritt, Neustart — bringt Sparkle selbst mit.

Die Vertrauenskette ist kurz und hängt an einem einzigen Punkt: Ohne gültige
EdDSA-Signatur wird nichts installiert. Das ist gut so, denn der zweite Punkt — die
Herkunft des Feeds — ist nicht abgesichert (siehe *Missbrauchsschutz*).

## Komponentenstruktur

```
MikaFileScopeApp
└── AppDelegate                              @MainActor, NSApplicationDelegate
    └── sparkleUpdater: SparkleUpdater       erzeugt beim App-Start, lebt so lange wie die App
        └── SPUStandardUpdaterController     startingUpdater: true
            ├── updater                      canCheckForUpdates · automaticallyChecksForUpdates
            │                                lastUpdateCheckDate · checkForUpdates(_:)
            ├── updaterDelegate: nil         ← nicht gesetzt
            └── userDriverDelegate: nil      ← nicht gesetzt

WindowGroup
└── .commands
    └── CommandGroup(after: .appInfo)
        └── Button "Check for Updates..."    .disabled(!canCheckForUpdates)
```

Von den vier nach außen gereichten Zugängen der Hülle wird genau **einer** benutzt:

| Zugang | Definiert in | Benutzt von |
|---|---|---|
| `checkForUpdates()` | `SparkleUpdater.swift:34` | Menüeintrag |
| `canCheckForUpdates` | `SparkleUpdater.swift:13` | Menüeintrag (`.disabled`) |
| `automaticallyChecksForUpdates` | `SparkleUpdater.swift:17` | **niemand** |
| `lastUpdateCheckDate` | `SparkleUpdater.swift:30` | **niemand** |

## Konfiguration statt Datenmodell

Dieses Feature hat keine Tabellen und keine eigenen Strukturen. Sein „Datenmodell" sind
vier Einträge in der `Info.plist` und was Sparkle selbst in den `UserDefaults` ablegt.

### `Resources/Info.plist`

| Schlüssel | Wert | Pflicht | Bedeutung |
|---|---|---|---|
| `SUFeedURL` | `https://raw.githubusercontent.com/daumedia/MikaFileScope/master/appcast.xml` | ja | Wo Sparkle nachsieht. **Im ausgelieferten Bundle steht hier noch `Mukaarts`** |
| `SUPublicEDKey` | `eauiHgP4PM9ynLekAmo3URrX3ye3HW7D53xOZa5AeYI=` | ja | Öffentlicher EdDSA-Schlüssel. Erzwingt die Signaturprüfung |
| `CFBundleVersion` | `1` | ja | **Der Wert, den Sparkle vergleicht.** Steht seit dem ersten Commit still |
| `CFBundleShortVersionString` | `2.0.0` | ja | Nur Anzeige. Für den Versionsvergleich ohne Bedeutung |

**Nicht gesetzt** — es gelten Sparkles Voreinstellungen:

| Schlüssel | Folge des Fehlens |
|---|---|
| `SUEnableAutomaticChecks` | Sparkle fragt beim ersten Start nach — Einwilligung wird eingeholt |
| `SUScheduledCheckInterval` | Standardabstand zwischen planmäßigen Prüfungen |
| `SUEnableSystemProfiling` | **aus** — kein Systemprofil wird übertragen |

### `appcast.xml` — Aufbau wie er ist

| Element | Vorhanden | Anmerkung |
|---|---|---|
| `<rss>` mit Sparkle-Namensraum | ja | syntaktisch gültig |
| `<channel>` mit Titel, Link, Beschreibung, Sprache | ja | `<link>` zeigt auf das Repository |
| **`<item>`** | **nein** | Ohne Eintrag gibt es nichts zu aktualisieren |

Ein wirksamer Eintrag bräuchte: `<sparkle:version>` (die Build-Nummer),
`<sparkle:shortVersionString>`, `<enclosure>` mit URL, Länge und
`sparkle:edSignature`, dazu `sparkle:minimumSystemVersion`.

### Von Sparkle selbst verwaltet

Sparkle legt eigene Schlüssel in der `UserDefaults`-Domain der App ab — letzter
Prüfzeitpunkt, Einwilligung zur automatischen Prüfung, übersprungene Versionen.
Geschrieben von der Bibliothek, nicht von diesem Code, und nirgends von der App gelesen.

## Zugriffsregeln

Kein Mehrbenutzersystem, keine Rollen. Die einzige Zugriffsfrage ist die **Vertrauens-
kette**: Wem gehorcht die App, wenn sie Code nachlädt?

| Stufe | Prüfung | Erzwungen durch | Zustand |
|---|---|---|---|
| Transport | HTTPS zum Feed | URL-Schema in `SUFeedURL` | ✓ wirksam |
| **Herkunft** | Ist der Feed unter unserer Kontrolle? | — | **✗ nicht abgesichert** — die URL enthält Konto- und Branchnamen; beide sind veränderlich |
| Inhalt | EdDSA-Signatur des Pakets | `SUPublicEDKey` | ✓ wirksam — ohne gültige Signatur keine Installation |
| Ausführung | Hardened Runtime, Gatekeeper | Signatur des Bundles | ⚠ nur Ad-hoc, nicht notarisiert (B10) |

Die dritte Zeile trägt die gesamte Sicherheit dieses Features. Fiele sie weg, wäre die
zweite Zeile unmittelbar ausnutzbar.

**Beschluss vom 2026-08-23 zur zweiten Zeile:** Der alte Kontoname `Mukaarts` wird
vorsorglich selbst registriert, damit die Herkunft des Feeds nicht in fremde Hand fallen
kann. Das ist eine Betriebsmaßnahme, keine Codeänderung — Einzelheiten in `spec.md`
unter *Sofortmaßnahme*.

## Missbrauchsschutz

| Angriff | Wirksamer Schutz | Lücke |
|---|---|---|
| Manipuliertes Update untergeschoben | EdDSA-Signaturprüfung gegen `SUPublicEDKey` | keine, solange der private Schlüssel sicher ist |
| Übernahme des Feeds über den freigegebenen Kontonamen `Mukaarts` | Signaturprüfung verhindert die **Installation** | Der Angreifer erhält die IP-Adressen aller prüfenden Installationen und kann über die von Sparkle angezeigten Release Notes eigene Inhalte einblenden |
| Rückstufung auf eine ältere, verwundbare Fassung | Versionsvergleich | greift nicht, weil `CFBundleVersion` konstant `1` ist — der Vergleich ist wirkungslos |
| Abhören der Verbindung | HTTPS | keine |
| Übermäßige Abfragen | Sparkles eigener Prüfabstand | kein eigenes Rate Limit; entfällt, weil der Abruf nichts kostet |

**Kosten pro Aufruf:** keine. Der Feed liegt auf GitHub, das DMG auf GitHub Releases —
beides kostenfrei. Ein Rate Limit ist nicht erforderlich.

## Externe Dienste

| Dienst | Wofür | Was hingeht | Was vorher entfernt wird |
|---|---|---|---|
| raw.githubusercontent.com (Fastly) | Abruf von `appcast.xml` | IP-Adresse, User-Agent mit App-Name und Version, Zeitpunkt | nichts zu entfernen — es werden keine App-Daten gesendet |
| github.com Releases | Download des DMG | dasselbe | dito |

Kein Systemprofil (`SUEnableSystemProfiling` nicht gesetzt), keine Scandaten, keine
Dateipfade. Nachgewiesen in `docs/datenschutz.md`, Abschnitt 2.

## Erkennbare Entscheidungen

| # | Entscheidung | Alternative | Warum so — soweit rekonstruierbar |
|---|---|---|---|
| 1 | Sparkle statt Eigenbau | eigener Update-Prüfer gegen die GitHub-API | Auf macOS der Standard; Signaturprüfung, Installation und Neustart sind gelöst. Gleiches Muster wie MikaGrid und MikaScreenSnap laut `CLAUDE.md` |
| 2 | Dünne Hülle um `SPUStandardUpdaterController` | Sparkle direkt in der View benutzen | Hält `@preconcurrency import` und die AppKit-Berührung an einer Stelle; die App bleibt Swift-6-tauglich |
| 3 | Updater im `AppDelegate` statt in einer View | `@State` in `ContentView` | Der Updater muss den Fensterschluss überleben — im Menüleisten-Modus läuft die App ohne Fenster weiter |
| 4 | Feed auf GitHub raw | eigener Server, GitHub Pages, Vercel | Kein Server nötig, versioniert, kostenlos. Der Preis: Konto- und Branchname sind fester Bestandteil der URL |
| 5 | Branch `master` in der Feed-URL | `main` | **Grund nicht erkennbar.** Beide Branches existieren; gearbeitet wird auf `main`. Vermutlich ein Überbleibsel aus der Zeit vor der Umstellung |
| 6 | `updaterDelegate: nil` | eigenes Delegate für Fehler und Protokoll | Grund nicht erkennbar. Vermutlich der kürzeste Weg zum Laufen |
| 7 | Keine Voreinstellung für automatische Prüfung | `SUEnableAutomaticChecks = true` | Grund nicht erkennbar. Das Ergebnis — Sparkle fragt den Nutzer — ist datenschutzrechtlich die bessere Variante, ob beabsichtigt oder nicht |

## Abdeckung der Akzeptanzkriterien

| AK | Erfüllt durch | Anmerkung |
|---|---|---|
| AK-01 | `AppDelegate.sparkleUpdater`, `startingUpdater: true` | |
| AK-02 | `CommandGroup(after: .appInfo)` in `MikaFileScopeApp` | |
| AK-03 | `.disabled(!canCheckForUpdates)` | |
| AK-04 | Fehlen von `SUEnableAutomaticChecks` → Sparkle-Erstdialog | Verhalten der Bibliothek, nicht des Codes |
| AK-05 | `checkForUpdates()` → `SUFeedURL` | |
| AK-06 | Sparkle-Versionsvergleich über `CFBundleVersion` | **heute wirkungslos**, siehe AK-14 |
| AK-07 | `SUPublicEDKey` | die tragende Schutzmaßnahme |
| AK-08 | Sparkles Standardoberfläche | ohne eigene Fehlerbehandlung (FB-B09-07) |
| AK-09 | getrennte Zuständigkeiten — `ScanEngine` und Updater berühren sich nicht | |
| AK-10 | kein Netzwerkcode in `Sources/` | nachgewiesen per `grep`, siehe `docs/datenschutz.md` |
| AK-11 | Fehlen von `SUEnableSystemProfiling` | |
| AK-12 | `https://` in `SUFeedURL` | |

**AK-13 bis AK-16 sind entfallen.** Sie wurden am 2026-08-23 als Fehler eingestuft und
in den *Fehlbestand* der Spec überführt (FB-B09-01, -02, -03, -11). Ihre Nummern bleiben
unbesetzt, damit Verweise eindeutig bleiben. Was sie beschrieben, wird von keiner
Komponente „erfüllt" — es ist der Defekt selbst:

| ehem. AK | Fundstelle | jetzt |
|---|---|---|
| AK-13 | `appcast.xml` ohne `<item>` | FB-B09-01 |
| AK-14 | `Resources/Info.plist:19` — `CFBundleVersion = 1` | FB-B09-02 |
| AK-15 | `build/Mika+FileScope.app/Contents/Info.plist` — `Mukaarts` | FB-B09-03 |
| AK-16 | `Resources/Info.plist:28` — Branch `master` | FB-B09-11 |

**Ohne Zuordnung — Hinweis auf toten Code:** `automaticallyChecksForUpdates` und
`lastUpdateCheckDate`. Kein Kriterium verlangt sie, kein Aufrufer benutzt sie. Sie sind
in `spec.md` als FB-B09-05 und FB-B09-06 vermerkt.
