# Mika+FileScope — Design-System

Stand: 2026-08-23 · Stack-Profil: `swiftui-macos`
Rückwirkend aus `Sources/` gelesen. **Dokumentiert, nicht bereinigt** — eine
Aufräumaktion ist ein eigenes Feature mit eigener Spec, keine Nebenwirkung der Erfassung.

## Farben

Definiert in `Sources/MikaPlusColors.swift`, gedacht als gemeinsame Palette des
Mika+-Ökosystems. Jede Farbe existiert doppelt: als `NSColor.MikaPlus.*` für AppKit und
als `Color.MikaPlus.*` für SwiftUI, erzeugt über einen `NSColor(hex:)`-Initialisierer.

| Token | Hex | Gedacht für | Verwendungen im Code |
|---|---|---|---|
| `tealPrimary` | `#1D9E75` | Markenfarbe, Akzent | **11** |
| `destructive` | `#E24B4A` | Warnung, verschwendeter Platz | **1** |
| `tealLight` | `#5DCAA5` | hellere Abstufung | 0 |
| `tealLightest` | `#9FE1CB` | hellste Abstufung | 0 |
| `tealSurface` | `#E1F5EE` | Flächen | 0 |
| `darkBg` | `#1A1A2E` | dunkler Hintergrund | 0 |
| `darkBgDeep` | `#0F0F1A` | tiefster Hintergrund | 0 |
| `textPrimary` | `#E1F5EE` | Text auf dunkel | 0 |
| `textSecondary` | `#9FE1CB` | Sekundärtext auf dunkel | 0 |

**Sieben der neun Token werden nirgends benutzt.** Die App trägt eine vollständige
Markenpalette mit sich und färbt tatsächlich mit zwei Farben. Alles Übrige überlässt sie
den Systemfarben — `.secondary`, `.background`, `.gray` —, was Dark und Light Mode ohne
Zutun korrekt macht, aber bedeutet: Mika+FileScope sieht aus wie eine Systemanwendung
mit einem grünen Akzent, nicht wie ein Mitglied einer Markenfamilie.

### Die Diagrammpalette und ihre Herleitung

```swift
static let chartPalette: [Color] = (0..<8).map { i in
    Color(hue: (148.0/360.0) + Double(i) * (45.0/360.0), saturation: 0.70, brightness: 0.75)
}
```

Der Kommentar darüber lautet „derived from teal primary via hue rotation". **Das trifft
nicht zu**, nachgerechnet:

| | Farbton | Sättigung | Helligkeit | Hex |
|---|---|---|---|---|
| `tealPrimary` | 160,9° | 0,82 | 0,62 | `#1D9E75` |
| `chartPalette[0]` | 148,0° | 0,70 | 0,75 | `#39BF77` |

Die erste Diagrammfarbe ist um 13° verschoben, blasser und heller — sie ist **nicht** die
Markenfarbe. In der Tabellenansicht steht der Farbbalken einer Zeile deshalb direkt neben
Fortschrittsbalken in `tealPrimary`, in zwei ähnlichen, aber unterschiedlichen Grüntönen.

Der Farbtonabstand von 45° verteilt acht Farben gleichmäßig über den Kreis. Bei fester
Sättigung und Helligkeit heißt das: Gelb- und Cyantöne wirken deutlich heller als die
Blau- und Violettanteile, obwohl sie denselben `brightness`-Wert tragen. Für
Kategorien, die gleichwertig nebeneinanderstehen, ist das eine ungleiche Gewichtung.

**Neunte Farbe:** Der Sammelposten „Other" ist fest `.gray`, außerhalb der Palette.

### Der Zeitachsen-Verlauf

`HistogramView.gradientColor(for:)` erzeugt seine Farben eigenständig — ohne
`MikaPlusColors`:

```swift
Color(hue: 148.0/360.0,
      saturation: 0.70 * (1.0 - progress * 0.6),
      brightness: 0.75 * (1.0 - progress * 0.3))
```

Neuere Dateien erscheinen kräftig, ältere entsättigt und dunkler. Der Ansatz ist
schlüssig, aber die Zahlen `148`, `0.70` und `0.75` stehen hier ein **zweites Mal**
fest im Code. Wer die Markenfarbe ändert, ändert die Diagramme und die Zeitachse nicht
mit — und merkt es an zwei verschiedenen Stellen nicht.

## Typografie

Keine eigene Schriftart. Verwendet wird durchgehend die Systemschrift, teils über
semantische Textstile, teils über feste Punktgrößen.

**Semantisch (24 Vorkommen)** — skaliert mit den Systemeinstellungen:

| Stil | Vorkommen | Wo |
|---|---|---|
| `.caption` | 10 | Beschriftungen, Pfade, Legenden |
| `.caption2` | 5 | Achsenbeschriftungen, Kleinstwerte |
| `.headline` | 4 | Diagrammüberschriften, Blattkopf |
| `.title3` | 3 | Leerzustände |
| `.subheadline` | 2 | Untertitel der Diagramme |

**Fest verdrahtet (9 Vorkommen)** — ignoriert die Systemeinstellungen:

| Größe | Wo |
|---|---|
| 56 pt | Symbol im Leerzustand |
| 40 pt | Symbol bei „keine Treffer" und „keine Duplikate" (2×) |
| 28 pt | Symbol im Menüleisten-Leerzustand |
| 16 pt | Symbol im Menüleisten-Kopf |
| 14 pt, `.semibold` | Titel im Menüleisten-Kopf |
| 12 pt, `.medium` | Ordnername in der Menüleiste |
| 11 pt | „Rescan" und „Quit" in der Menüleiste (2×) |

Bei Symbolen ist eine feste Größe vertretbar. Bei den Textelementen der
Menüleisten-Kurzfassung — 14, 12 und 11 pt — ist es eine bewusste oder unbewusste
Abkopplung von Dynamic Type: Wer die Systemschrift vergrößert, sieht im Hauptfenster
größere Schrift, im Popover nicht.

**Zifferndarstellung:** Alle Zahlen laufen über `.monospacedDigit()`, damit Werte beim
Aktualisieren nicht springen. Endungen stehen in `design: .monospaced`. Beides ist
konsequent durchgehalten.

## Abstände

Hier zeigt sich der erwartete Wildwuchs am deutlichsten.

**`spacing`, 8 verschiedene Werte:** 0 (4×), 2, 4, 6, 8 (7×), 12 (4×), 16 (6×), 32 (3×).
Die Häufungen bei 8, 16 und 32 deuten auf ein 8er-Raster hin — 2, 4, 6 und 12 fallen
heraus.

**`padding`, 13 verschiedene Zahlenwerte:** 5, 6, 8, 10, 12, 14, 16, 20, 24, 40, dazu
zweimal `.padding()` ohne Wert (Systemvorgabe) und einmal `.padding(.horizontal)`.

Konkret nebeneinander in `ContentView`:

| Element | Abstand |
|---|---|
| Kennzahlenleiste | horizontal 20, vertikal 12 |
| Kategorieleiste | horizontal 20, vertikal 6 |
| Kategorie-Chip | horizontal 10, vertikal 5 |
| Kennzahl-Pille | horizontal 14, vertikal 8 |
| Tab-Umschalter | oben 12 |

Fünf Elemente in einer Ansicht, fünf verschiedene Abstandspaare, kein erkennbares
Raster. Kein Token, keine Konstante — jeder Wert steht als Zahl an seiner Stelle.

## Radien und Flächen

| Radius | Wo |
|---|---|
| 2 pt | Farbbalken links in der Tabellenzeile |
| 4 pt | Diagrammsegmente und Balken (4×) |
| 8 pt | Kennzahl-Pille |
| 12 pt | gestrichelter Rahmen des Ablagebereichs |
| `Capsule()` | Kategorie-Chips |

**Flächenfarben** entstehen ausschließlich über Transparenz auf Systemfarben:
`.secondary.opacity(0.1)` für Pillen und inaktive Chips, `tealPrimary.opacity(0.2)` für
den aktiven Chip. Drei Werte, zwei davon identisch — hier ist der Bestand ausnahmsweise
konsistent.

## Wiederkehrende Bausteine

| Baustein | Wo definiert | Wiederverwendet |
|---|---|---|
| `StatPill` | `ContentView.swift`, `private struct` | nein — die Menüleiste hat mit `miniStat(value:label:)` eine eigene, optisch abweichende Fassung |
| Kategorie-Chip | inline in `categoryBar` | nein |
| Leerzustand (Symbol + Text) | dreimal ausformuliert: `emptyState`, `noMatchState`, `noDuplicatesView` | nein — dreimal dasselbe Muster in drei Größen (56/40/40 pt) |
| Diagrammlegende | inline in `ChartView` | nein |

**Es gibt keine gemeinsame Komponentendatei.** Jede Ansicht bringt ihre Bausteine
selbst mit. Bei 1.454 Zeilen ist das tragbar; als Muster für weitere Ansichten trägt es
nicht.

## Bewegung

Eine einzige Animation im gesamten Projekt:

```swift
.animation(.spring(response: 0.6, dampingFraction: 0.8), value: groups.map(\.id))
```

in `ChartView`. Sie greift bei einer Änderung der Gruppen-IDs — also bei jedem Neuscan
und jedem Filterwechsel. Tabelle, Zeitachse und Kategorieleiste wechseln ohne Übergang.

## Symbole

Ausschließlich SF Symbols, keine eigenen Grafiken in der Oberfläche. Acht davon sind
den Kategorien fest zugeordnet (`FileCategory.icon`), der Rest steht inline:
`folder.badge.plus`, `arrow.clockwise`, `eye.slash`, `square.and.arrow.up`,
`doc.on.doc`, `menubar.rectangle`, `folder.badge.questionmark`,
`line.3.horizontal.decrease.circle`, `checkmark.circle`, `magnifyingglass`,
`doc.viewfinder` (Menüleiste und App-Symbol).

## Erscheinungsbild

Dark und Light Mode funktionieren ohne eigenes Zutun, weil fast alles auf Systemfarben
beruht. Der einzige harte Wert im Fenster ist `.background(.background)` — ebenfalls
adaptiv. Die Marken-Dunkelfarben `darkBg` und `darkBgDeep` sind definiert, aber
ungenutzt; die App erzwingt kein eigenes Dunkeldesign.

Die Screenshots der Website sind in Dark Mode aufgenommen, 1280 × 820, als WebP.

## Fehlbestand

| # | Beobachtung | Folge |
|---|---|---|
| DS-01 | `chartPalette[0]` ist `#39BF77`, nicht die Markenfarbe `#1D9E75` — der Codekommentar behauptet die Herleitung, die Zahlen widerlegen sie | Zwei ähnliche Grüntöne stehen in der Tabelle nebeneinander; die Marke ist im Diagramm nicht vertreten |
| DS-02 | Sieben von neun Farbtoken sind ungenutzt | Die Palette suggeriert ein Markenbild, das die App nicht umsetzt. Entweder anwenden oder streichen |
| DS-03 | Die Werte `148`, `0.70`, `0.75` stehen doppelt im Code — in `MikaPlusColors` und in `HistogramView` | Eine Änderung der Markenfarbe erreicht die Zeitachse nicht |
| DS-04 | 13 verschiedene `padding`- und 8 verschiedene `spacing`-Werte, keine Konstanten | Neue Ansichten haben keinen Anhaltspunkt; jede Abweichung ist unsichtbar |
| DS-05 | Neun feste Schriftgrößen, davon vier für Text in der Menüleisten-Kurzfassung | Dynamic Type wirkt dort nicht — ein Barrierefreiheitsthema, kein Geschmacksthema |
| DS-06 | Der Leerzustand ist dreimal ausformuliert statt einmal als Komponente | Änderungen am Muster müssen an drei Stellen nachgezogen werden |
| DS-07 | `StatPill` und `miniStat` zeigen dasselbe, sehen aber unterschiedlich aus | Hauptfenster und Menüleiste driften bei jeder Änderung weiter auseinander |
| DS-08 | Die Diagrammpalette hält Sättigung und Helligkeit über alle Farbtöne konstant | Gelb- und Cyantöne dominieren optisch, obwohl alle Kategorien gleichwertig sind |
