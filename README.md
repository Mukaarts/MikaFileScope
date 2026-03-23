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

- Timeline: modified date histogram
- Duplicate file detection by size + hash
- Menubar quick-scan mode
- Sparkle auto-updates
- DMG distribution

## License

Copyright 2025 dauMedia / Mika. All rights reserved.
