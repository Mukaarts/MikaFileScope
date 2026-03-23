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
- **MikaPlusColors** — Mika+ brand colors, `NSColor(hex:)`, chart palette (8 hue rotations from #1D9E75)

## Conventions

- Swift 6 strict concurrency: `@MainActor` for UI, `nonisolated static` for background work
- `@Observable` (not Combine) for state management
- `NSSavePanel`/`NSOpenPanel` for file dialogs (AppKit interop)
- Brand colors via `Color.MikaPlus` / `NSColor.MikaPlus` (shared across Mika+ ecosystem)
- No external dependencies (Phase 1)

## Git Workflow

- New branch per feature/bugfix/refactor
- Update CHANGELOG.md, README.md, and CLAUDE.md before each commit
