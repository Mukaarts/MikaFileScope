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
- Sparkle 2.6+ for auto-updates (SUFeedURL: GitHub raw/master appcast.xml)

## Distribution

- `bash scripts/build.sh` — build release + assemble .app bundle + embed Sparkle + codesign
- `bash scripts/create-dmg.sh` — create DMG with create-dmg CLI (brew install create-dmg)
- `bash scripts/create-dmg-simple.sh` — fallback DMG with hdiutil
- `.github/workflows/release.yml` — CI/CD on `v*` tags
- Signed **ad-hoc** (`codesign --sign -`), not notarized → Gatekeeper blocks the first launch
- `swift build -c release` produces a **host-architecture** binary only (arm64), not a universal one

## Website

- `website/` — static marketing landing page (HTML + CSS + ~60 lines vanilla JS, no build step)
- Vercel: import the repo with **Root Directory = `website`**, Framework Preset *Other*
- Palette mirrors `Sources/MikaPlusColors.swift`; keep the two in sync
- `swift scripts/GenerateOGImage.swift` — regenerates `website/assets/og-image.jpg` from the app icon
- Screenshots in `website/assets/shots/` are real captures, Dark Mode, 1280×820 window, WebP
- Version, download URL and file size are hard-coded in `website/index.html` — update them per release

## Git Workflow

- New branch per feature/bugfix/refactor
- Update CHANGELOG.md, README.md, and CLAUDE.md before each commit
