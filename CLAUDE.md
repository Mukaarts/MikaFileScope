# Mika+FileScope

Native macOS folder scanner — groups files by extension, visualizes with Swift Charts, exports CSV/JSON.

## Build & Run

```bash
swift build          # Debug build
swift run            # Build and run
swift build -c release  # Release build
open Package.swift   # Open in Xcode
```

## Platform

- macOS 14+ (Sonoma), Swift 6.0, Swift Package Manager
- No .xcodeproj — SPM only with `path: "Sources"` (flat structure)

## Architecture

- **ScanEngine** (`@Observable @MainActor final class`) — core scanning logic
  - Heavy work dispatched via `Task.detached` to `nonisolated static func performScan`
  - Uses `FileManager.enumerator(at:includingPropertiesForKeys:options:)`
- **ContentView** — main UI: toolbar, sortable Table, segmented tabs (List/Charts)
- **ChartView** — Swift Charts: donut (SectorMark) + horizontal bar (BarMark), top 8 + "Other"
- **ExportManager** — CSV/JSON generation + NSSavePanel
- **FileTypeGroup** — data model (`Identifiable, Hashable, Sendable`)
- **FileCategory** — enum for semantic file categories (Images, Documents, etc.) with extension sets
- **HistogramView** — date histogram with file count and size charts by age bucket
- **DuplicateDetector** — SHA-256 based duplicate detection with streaming hash (1 MB chunks)
- **DuplicateResultView** — sheet UI for duplicate results with Reveal in Finder
- **MenubarPopoverView** — compact menubar popover with scan summary
- **AppDelegate** — manages shared ScanEngine, SparkleUpdater, handles menubar lifecycle
- **SparkleUpdater** — Sparkle auto-update wrapper (identical pattern to MikaGrid/MikaScreenSnap)
- **MikaPlusColors** — Mika+ brand colors, `NSColor(hex:)`, chart palette (8 hue rotations from #1D9E75)

## Conventions

- Swift 6 strict concurrency: `@MainActor` for UI, `nonisolated static` for background work
- `@Observable` (not Combine) for state management
- `NSSavePanel`/`NSOpenPanel` for file dialogs (AppKit interop)
- Brand colors via `Color.MikaPlus` / `NSColor.MikaPlus` (shared across Mika+ ecosystem)
- Sparkle 2.9 für automatische Updates (SUFeedURL: GitHub raw/**main** appcast.xml) — nur im Direktvertrieb

## Distribution

- `bash scripts/build.sh` — Direktvertrieb: Release bauen, Bundle zusammensetzen, Sparkle einbetten, signieren
- `bash scripts/build.sh --appstore` — Store-Variante: Sandbox, **ohne** Sparkle (`APPSTORE=1`)
- `bash scripts/build.sh --universal` — arm64 + x86_64 statt nur der Host-Architektur
- `bash scripts/create-dmg.sh` — create DMG with create-dmg CLI (brew install create-dmg)
- `bash scripts/create-dmg-simple.sh` — fallback DMG with hdiutil
- `.github/workflows/release.yml` — CI/CD on `v*` tags
- `bash scripts/build.sh --release` signiert mit der Developer ID aus dem Schlüsselbund
  und baut universal; `bash scripts/notarize.sh` notarisiert und tackert das DMG
- **Ad-hoc-Signatur macht den Update-Kanal unbrauchbar**: Sparkles Installer bricht dann
  mit „An error occurred while running the updater" ab. Mit Developer ID läuft er durch
  (nachgewiesen am 2026-08-24). Für alles, was das Haus verlässt, gilt `--release`
- Zwei Entitlement-Dateien: `MikaFileScope.entitlements` (Direktvertrieb, ohne Sandbox)
  und `MikaFileScope-AppStore.entitlements` (Sandbox, `user-selected.read-only`, Bookmarks)
- `swift build -c release` erzeugt nur die Host-Architektur; `--universal` baut beide

## Website

- `website/` — static marketing landing page (HTML + CSS + ~60 lines vanilla JS, no build step)
- Live at **filescope.daumedia.lu** (Vercel, **Root Directory = `website`**, Framework Preset *Other*)
- Absolute URLs live in `index.html` (canonical/OG/JSON-LD), `robots.txt` and `sitemap.xml` — change all three together
- Palette mirrors `Sources/MikaPlusColors.swift`; keep the two in sync
- `swift scripts/GenerateOGImage.swift` — regenerates `website/assets/og-image.jpg` from the app icon
- Screenshots in `website/assets/shots/` are real captures, Dark Mode, 1280×820 window, WebP
- Version, download URL and file size are hard-coded in `website/index.html` — update them per release

## SDD-Artefakte

- **Artefaktpfad: `docs/`** — alle `sdd-`-Skills lesen ihn hier und in Zeile 3 von `docs/prd.md`
- `docs/prd.md` · `docs/datenmodell.md` · `docs/design-system.md` · `docs/app-shell.md` · `docs/datenschutz.md`
- `features/index.md` — Statustabelle aller Features, das Projektmanagement der Kette
- `features/BNN-slug/` — je Bestandsfeature `spec.md`, `design.md` und `qa-report.md`, alle auf `review`
- Bestandsfeatures tragen `B`-IDs (`B01`–`B11`), rückwirkend erfasst am 2026-08-23.
  Neue Features bekommen numerische IDs (`01` = Mac App Store, geplant)
- `features/befunde.md` — projektweite Befundliste, von `sdd-qa` fortgeschrieben
- `docs/audit-2026-08.md` — **Auditbericht über alle elf Features** (Abschluss vom 2026-08-24)
- Stand 2026-08-24: **alle 11 Features geprüft**, 142 Akzeptanzkriterien — 119 bestanden,
  1 durchgefallen, 22 nicht prüfbar. 5 hohe und 13 mittlere Befunde offen, 4 behoben
  (alle in B09, noch nicht ausgeliefert)
- `Tests/UpdateChannelTests/` — die ersten Tests des Projekts; `swift test` prüft den
  Update-Kanal gegen `Info.plist` und `appcast.xml`, Laufzeit 0,002 s
- **Offen und dringend:** GitHub-Kontoname `Mukaarts` sichern — ausgelieferte Kopien von
  v2.0.0 fragen dort ihren Sparkle-Feed ab. Es ist der frühere Name **desselben** Kontos
  (umbenannt in `daumedia`), aber nach der Umbenennung unbesetzt und neu registrierbar;
  die alte Adresse trägt nur über die Repository-Weiterleitung (BF-02)

## Git Workflow

- New branch per feature/bugfix/refactor
- Update CHANGELOG.md, README.md, and CLAUDE.md before each commit
