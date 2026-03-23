# Mika+FileScope

A native macOS utility that scans folders, groups files by extension, and visualizes the results with interactive charts and a sortable list.

Part of the **Mika+** ecosystem.

## Features

- Recursive folder scanning with file type grouping
- Sortable table view (extension, count, size, percentage)
- Donut chart and horizontal bar chart (Swift Charts)
- CSV and JSON export via save dialog
- Drag-and-drop folder support
- Non-blocking background scanning for large directories
- Dark and Light mode support
- Hidden files toggle (include/exclude dotfiles in scans)
- File category filter (Images, Documents, Videos, Audio, Code, Archives, Other)
- Timeline tab with file age distribution histogram
- Duplicate file detection by SHA-256 hash with Reveal in Finder
- Optional menubar quick-scan mode with compact summary popover

## Requirements

- macOS 14.0+ (Sonoma)
- Xcode 15+ / Swift 6.0

## Build & Run

```bash
# Build
swift build

# Run
swift run

# Release build
swift build -c release
```

Or open in Xcode:

```bash
open Package.swift
```

## Phase 2 (Planned)

- Sparkle auto-updates
- DMG distribution

## License

Copyright 2025 dauMedia / Mika. All rights reserved.
