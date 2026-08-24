# B01 · Ordner scannen — Systemdesign

Status: `review` · Stand: 2026-08-24 · geprüft, siehe `qa-report.md`

**Kein Code in diesem Dokument.**

## Überblick

`ScanEngine` ist eine `@Observable @MainActor`-Klasse, die den Zustand hält, aber nicht
selbst arbeitet. Die eigentliche Arbeit macht `performScan` — eine `nonisolated static`
Funktion ohne Zugriff auf den Zustand, aufgerufen über `Task.detached`. Sie bekommt
Ordner-URL und Schalterstellung als Kopie, liefert eine `Sendable`-Struktur zurück, und
erst deren Übernahme geschieht wieder auf dem Main Actor.

Das ist die saubere Swift-6-Trennung: kein geteilter veränderlicher Zustand zwischen
den Nebenläufigkeitsbereichen. Was fehlt, ist die Gegenrichtung — es gibt keinen Weg,
von außen in den laufenden Durchlauf hineinzugreifen, weder zum Abbrechen noch zum
Melden von Fortschritt.

## Ablauf eines Scans

```
Nutzer wählt Ordner (NSOpenPanel) ODER legt ihn ab (onDrop)
└── ScanEngine.scan(folder:)                     @MainActor
    ├── isScanning = true, errorMessage = nil, scannedFolderURL = url
    ├── includeHidden wird als Kopie mitgegeben
    └── Task.detached
        └── ScanEngine.performScan(at:includeHidden:)   nonisolated
            ├── startAccessingSecurityScopedResource()  ← ohne Sandbox wirkungslos
            ├── FileManager.enumerator(at:includingPropertiesForKeys:options:)
            │   keys:    fileSize · isDirectory · contentModificationDate
            │   options: includeHidden ? [] : [.skipsHiddenFiles]
            ├── je Eintrag:  Verzeichnis? → überspringen
            │                Lesefehler?  → überspringen (still)
            │                sonst:       → dict[ext], dateBucketDict[fenster], fileURLs
            └── Result<ScanResult, Error>
    └── MainActor.run { Zustand übernehmen oder errorMessage setzen }
```

## Komponentenstruktur

```
ContentView
├── toolbarContent
│   ├── Button "Choose Folder"      → chooseFolder() → NSOpenPanel
│   ├── Text: Ordnername            .help(vollständiger Pfad)
│   ├── Button "Rescan"             → engine.rescan()   .disabled(kein Ordner || isScanning)
│   ├── Toggle "Hidden Files"       → engine.includeHidden + sofortiger rescan()
│   └── ProgressView                nur während isScanning
├── emptyState                      Symbol · Text · Schaltfläche · Ablagerahmen
├── .onDrop(of: [.fileURL])         → handleDrop(providers:)
└── .alert("Scan Error")            gebunden an engine.errorMessage

ScanEngine                          @Observable @MainActor
├── scan(folder:)                   startet den Durchlauf
├── rescan()                        guard scannedFolderURL
├── reset()                         ← nirgends aufgerufen
├── performScan(at:includeHidden:)  nonisolated static
└── dateBucketKey(for:)             nonisolated static — gehört fachlich zu B05
```

## Zustandsfelder

| Feld | Typ | Gesetzt von | Gelesen von |
|---|---|---|---|
| `isScanning` | Bool | `scan`, Abschluss | Spinner, „Rescan"-Sperre |
| `scannedFolderURL` | URL? | `scan` | Titel, „Rescan", Leerzustand, B08 |
| `groups` | [FileTypeGroup] | Abschluss | B02, B03, B04, B08 |
| `totalFiles`, `totalSize` | Int, Int64 | Abschluss | Kennzahlen, B08 |
| `dateBuckets` | [DateBucket] | Abschluss | B05 |
| `scannedURLs` | [URL] | Abschluss | B06 |
| `errorMessage` | String? | Fehlerfall | Warnhinweis |
| `includeHidden` | Bool | Schalter | `scan` |

**Keine Persistenz.** Alle Felder sind nach dem Beenden verloren; Einzelheiten in
`docs/datenmodell.md`.

## Zugriffsregeln

Kein Mehrbenutzersystem. Die einzige Zugriffsfrage ist der Dateisystemzugriff:

| Heute | Erzwungen durch |
|---|---|
| Die App liest, was der angemeldete Nutzer lesen darf | macOS selbst — TCC fragt bei Schreibtisch, Dokumenten, Downloads nach |
| **Nur lesend.** Kein Code-Pfad verändert oder löscht eine fremde Datei | Aufbau — es gibt keine Schreiboperation außer dem Export (B07) |
| `startAccessingSecurityScopedResource()` | **wirkt nicht** — kein Bookmark, keine Sandbox (FB-B01-01) |

Nach Feature `01`: `com.apple.security.files.user-selected.read-only`, Zugriff nur auf
den ausdrücklich gewählten Ordner, Bookmarks für den Neustart.

## Missbrauchsschutz

| Risiko | Schutz | Lücke |
|---|---|---|
| Sehr großer Ordner blockiert die App | Hintergrundausführung | Speicher wächst unbegrenzt (FB-B01-05), kein Abbruch (FB-B01-03) |
| Gleichzeitige Scans verfälschen das Ergebnis | „Rescan" ist gesperrt | Schalter und Ablagefläche sind es **nicht** (AK-21) |
| Unerwartete Ablage (Datei statt Ordner) | Prüfung auf `isDirectory` | Fehlschlag ist stumm (EC-08) |
| Kosten pro Aufruf | entfällt — rein lokal | — |

## Externe Dienste

Keine. Der Scan ist vollständig lokal; es gibt keinen Netzwerkcode (nachgewiesen in
`docs/datenschutz.md`).

## Erkennbare Entscheidungen

| # | Entscheidung | Alternative | Warum so |
|---|---|---|---|
| 1 | `Task.detached` + `nonisolated static` | `async` auf dem Actor, `DispatchQueue` | Der einzige Weg, unter Swift 6 strict concurrency echte Hintergrundarbeit ohne geteilten Zustand zu bekommen |
| 2 | Ergebnis als eine `Sendable`-Struktur | einzelne Werte nacheinander zurückreichen | Ein Übergabepunkt, ein Zustandswechsel — keine halb aktualisierte Oberfläche |
| 3 | `enumerator` statt `contentsOfDirectory` mit Rekursion | Eigenrekursion | Tiefensteuerung und Optionen kommen fertig mit; dafür auch die Voreinstellung, Pakete zu betreten (AK-19) |
| 4 | Schalter löst sofort einen Neuscan aus | erst beim nächsten „Rescan" wirken | Unmittelbar verständlich. Preis: der ungeschützte Parallelfall (AK-21) |
| 5 | Lesefehler überspringen | sammeln und melden | Grund nicht erkennbar; robust, aber stumm (AK-20) |
| 6 | Nur der erste Anbieter beim Ablegen | alle verarbeiten | Grund nicht erkennbar. Mehrfachauswahl ist auch im Dialog abgeschaltet — vermutlich bewusst „ein Ordner zur Zeit" |

## Abdeckung der Akzeptanzkriterien

| AK | Erfüllt durch |
|---|---|
| AK-01, AK-02 | `ContentView.chooseFolder()` — `NSOpenPanel`, `canChooseFiles = false` |
| AK-03, AK-04 | `.onDrop` + `handleDrop`, `isDropTargeted` |
| AK-05 | `emptyState` |
| AK-06 | `isScanning` → `ProgressView`; `Task.detached` hält die Oberfläche frei |
| AK-07 | `FileManager.enumerator` (rekursiv per Voreinstellung) |
| AK-08 | `resourceValues.isDirectory == true → continue` |
| AK-09 | `FileTypeGroup.displayExt` |
| AK-10 | `pathExtension.lowercased()` |
| AK-11 | `sorted { $0.count > $1.count }` |
| AK-12 | `summaryBar` mit `StatPill` ×3 |
| AK-13 | `options = [.skipsHiddenFiles]` |
| AK-14 | Setter des Schalters ruft `engine.rescan()` |
| AK-15, AK-16 | `rescan()` bzw. `.disabled(…)` |
| AK-17, AK-18 | `NSError` in `performScan` → `errorMessage` → `.alert` |


**AK-19, AK-20, AK-21, AK-22, AK-23 sind entfallen.** Sie wurden am 2026-08-23 als Fehler eingestuft
und in den *Fehlbestand* der Spec überführt; ihre Nummern bleiben unbesetzt. Was sie
beschrieben, wird von keiner Komponente erfüllt — es ist der Defekt selbst.

**Ohne Zuordnung:** `reset()` (toter Code, FB-B01-06) und `dateBucketKey(for:)` — letztere
liegt in `ScanEngine`, erfüllt aber Kriterien von **B05** und ist dort abgedeckt.
