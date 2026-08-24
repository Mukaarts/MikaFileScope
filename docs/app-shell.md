# Mika+FileScope — App-Shell

Stand: 2026-08-23 · Stack-Profil: `swiftui-macos`
Was auf jeder Ansicht gleich ist: Fensteraufbau, Werkzeugleiste, Umschalter, Menü.

## Zwei Szenen, ein Zustand

`MikaFileScopeApp` deklariert zwei Szenen, die sich dieselbe `ScanEngine`-Instanz teilen.
Sie stammt aus dem `AppDelegate`, nicht aus einem `@State` — genau deshalb zeigt die
Menüleisten-Kurzfassung dasselbe Scanergebnis wie das Hauptfenster.

```
MikaFileScopeApp
├── WindowGroup                          Hauptfenster
│   └── ContentView(engine:)
│       ├── .windowResizability(.contentMinSize)
│       ├── .defaultSize(900 × 650)
│       └── .commands { CommandGroup(after: .appInfo) }
└── MenuBarExtra("FileScope", isInserted: $showMenubar)
    └── MenubarPopoverView(engine:)      .menuBarExtraStyle(.window)
```

`AppDelegate` hält `engine` und `sparkleUpdater` und beantwortet genau eine Frage des
Systems: `applicationShouldTerminateAfterLastWindowClosed` liest `showMenubar` und
liefert dessen Umkehrung. Ist die Menüleiste aktiv, überlebt die App das Schließen des
Fensters; ist sie es nicht, beendet sich die App wie üblich.

**Beachtenswert:** Derselbe Wert wird an drei Stellen unterschiedlich gelesen — zweimal
über `@AppStorage` (App und `ContentView`) und einmal direkt über
`UserDefaults.standard.bool(forKey:)` im `AppDelegate`. Der Schlüsselname `"showMenubar"`
steht als Zeichenkette dreimal im Code.

## Aufbau des Hauptfensters

Mindestmaß 800 × 600, Startgröße 900 × 650. Ein einziger senkrechter Stapel, dessen
Inhalt vom Scanzustand abhängt:

```
ContentView                              minWidth 800 · minHeight 600
├── [kein Ordner gewählt]
│   └── emptyState                       Symbol · Text · Schaltfläche · gestrichelter Ablagerahmen
└── [Ordner gewählt]
    ├── summaryBar                       StatPill ×3: Files · Total Size · Types
    ├── categoryBar                      waagerecht scrollende Chip-Leiste, 8 Kategorien
    ├── Divider
    ├── tabSwitcher                      segmentierter Umschalter, feste Breite 300
    └── mainContent
        ├── .list      → Table           4 Spalten, sortierbar
        ├── .charts    → ChartView       Donut + Balken
        └── .timeline  → HistogramView   zwei Balkendiagramme
```

Greift der Kategoriefilter und bleibt nichts übrig, ersetzt `noMatchState` den gesamten
Inhaltsbereich — Kennzahlenleiste, Kategorieleiste und Umschalter bleiben stehen.

## Werkzeugleiste

Eine `ToolbarItemGroup` mit `placement: .automatic`, acht Elemente in fester Reihenfolge:

| # | Element | Art | Deaktiviert wenn |
|---|---|---|---|
| 1 | Choose Folder | Schaltfläche, `tealPrimary` | nie |
| 2 | Ordnername | Text, `.caption`, Tooltip mit vollem Pfad | nur sichtbar, wenn gescannt |
| 3 | Rescan | Schaltfläche | kein Ordner oder Scan läuft |
| 4 | Hidden Files | Schalter, `.small` | nie — löst bei Änderung sofort einen Neuscan aus |
| 5 | Export | Menü mit „Export CSV" und „Export JSON" | gefilterte Menge ist leer |
| 6 | Find Duplicates | Schaltfläche | keine Dateien oder Scan läuft |
| 7 | Menubar | Schalter, `.small` | nie |
| 8 | Fortschrittsanzeige | `ProgressView`, `.small` | nur sichtbar während des Scans |

Die Leiste ist auch im Leerzustand vollständig sichtbar, dann größtenteils ausgegraut.
Sie trägt die gesamte Bedienung: **Es gibt keine Seitenleiste, kein Kontextmenü und
keine Tastenkürzel** außer den vom System vergebenen.

## Menüleiste des Systems

Ein einziger eigener Eintrag, über `CommandGroup(after: .appInfo)` direkt unter „Über":

```
Mika+FileScope
├── About Mika+FileScope                 (System)
├── Check for Updates…                   ← einziger eigener Befehl
└── …                                     (System)
```

Deaktiviert, solange `sparkleUpdater.canCheckForUpdates` falsch ist. Weitere eigene
Menüs — Datei, Ablage, Fenster — existieren nicht; dort steht ausschließlich, was
SwiftUI von sich aus mitbringt.

## Menüleisten-Kurzfassung

Feste Breite 280, `.menuBarExtraStyle(.window)`, Symbol `doc.viewfinder`.

```
MenubarPopoverView                       280 breit
├── headerView                           Symbol · „Mika+FileScope" · Spinner bei Scan
├── Divider
├── [gescannt]   scanSummary             Ordnername · 3 Kennzahlen · Top 5 mit Balken
├── [ungescannt] noScanView              Symbol · „No folder scanned"
├── Divider
└── footerView                           „Rescan" · „Quit"
```

**Die Kurzfassung ignoriert den Kategoriefilter.** Sie liest `engine.totalFiles`,
`engine.totalSize` und `engine.groups` — nicht die gefilterten Entsprechungen. Ist im
Hauptfenster „Images" aktiv, zeigt das Popover trotzdem den Gesamtbestand. Beide Zahlen
sind für sich richtig; nebeneinander widersprechen sie sich.

Einen Weg, aus dem Popover heraus einen Ordner zu wählen, gibt es nicht — nur „Rescan"
des bereits Gescannten. Ohne vorherigen Scan im Hauptfenster bleibt die Kurzfassung leer.

## Überlagerungen

| Art | Auslöser | Inhalt |
|---|---|---|
| Blatt (`.sheet`) | „Find Duplicates" | `DuplicateResultView`, 600 breit fixiert, 400–700 hoch. Schließt über „Done" |
| Warnhinweis (`.alert`) | `engine.errorMessage != nil` | Titel „Scan Error", eine Schaltfläche „OK", die die Meldung zurücksetzt |
| Systemdialog | „Choose Folder" | `NSOpenPanel`, nur Ordner, keine Mehrfachauswahl, `runModal()` |
| Systemdialog | Export | `NSSavePanel` mit vorbelegtem Namen `FileScope_<Ordner>.csv` bzw. `.json` |
| Systemdialog | Exportfehler | `NSAlert` mit „Export Failed" |

Beide Panels laufen **modal** über `runModal()` und blockieren den Main Actor, solange
sie offen sind. Bei einem Dialog ist das unauffällig; bemerkenswert ist es, weil ein
laufender Hintergrundscan dadurch seine Ergebnisse erst nach dem Schließen anzeigen kann.

## Ablage per Drag-and-drop

`.onDrop(of: [.fileURL])` liegt auf dem gesamten `ContentView`, nicht nur auf dem
Leerzustand — ein Ordner kann also auch über ein vorhandenes Ergebnis gezogen werden.
`isDropTargeted` färbt im Leerzustand Symbol und gestrichelten Rahmen in `tealPrimary`;
liegt bereits ein Ergebnis vor, gibt es **keine sichtbare Rückmeldung**.

`handleDrop` nimmt nur den ersten Anbieter, prüft, ob es sich um ein Verzeichnis
handelt, und startet den Scan. Alles andere — eine Datei, mehrere Objekte, ein nicht
auflösbarer Pfad — führt zum stillen Abbruch ohne Meldung, während `true` zurückgegeben
wird und die Ablage damit als angenommen gilt.

## Zustände der Shell im Überblick

| Zustand | Bedingung | Was sichtbar ist |
|---|---|---|
| Leer | `scannedFolderURL == nil && !isScanning` | Leerzustand, Werkzeugleiste größtenteils inaktiv |
| Scannend | `isScanning` | Spinner in der Leiste, vorheriges Ergebnis bleibt stehen |
| Ergebnis | Gruppen vorhanden | Kennzahlen, Kategorien, Umschalter, gewählte Ansicht |
| Gefiltert leer | `filteredGroups.isEmpty && !isScanning` | „No files match this category" statt des Inhalts |
| Fehler | `errorMessage != nil` | Warnhinweis über allem |

## Fehlbestand

| # | Beobachtung | Folge |
|---|---|---|
| AS-01 | Die Menüleisten-Kurzfassung ignoriert den Kategoriefilter | Zwei verschiedene Zahlen für denselben Ordner, gleichzeitig sichtbar |
| AS-02 | Der Schlüssel `"showMenubar"` steht dreimal als Zeichenkette im Code, in zwei verschiedenen Zugriffsarten | Ein Tippfehler beim Ändern bleibt beim Übersetzen unentdeckt |
| AS-03 | `handleDrop` liefert `true`, verwirft aber stillschweigend alles, was kein Ordner ist | Wer eine Datei ablegt, sieht keine Reaktion und keine Erklärung |
| AS-04 | Beim Ablegen über ein vorhandenes Ergebnis fehlt jede visuelle Rückmeldung | Der Nutzer weiß nicht, ob die Ablage angenommen wird |
| AS-05 | Keine Tastenkürzel für die Hauptaktionen — Ordner wählen, Neuscan, Export | Auf macOS eine ungewöhnliche Lücke; ⌘O und ⌘R wären erwartbar |
| AS-06 | `NSOpenPanel` und `NSSavePanel` laufen modal über `runModal()` | Blockiert den Main Actor; ein währenddessen fertig werdender Scan erscheint verzögert |
| AS-07 | Aus der Menüleisten-Kurzfassung heraus lässt sich kein Ordner wählen | Ohne Hauptfenster ist sie nur ein Anzeigeinstrument, kein Werkzeug |
| AS-08 | Die Oberfläche ist ausschließlich englisch, ohne Lokalisierungsdateien | Eine spätere Übersetzung berührt jede Ansicht |
