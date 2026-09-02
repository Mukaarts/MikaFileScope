# Mika+FileScope

A native macOS utility that scans folders, groups files by extension, and visualizes the results with interactive charts and a sortable list.

Part of the **Mika+** ecosystem.

**[Download on the Mac App Store](https://apps.apple.com/app/id6804743268)** — free. Also available as a signed DMG
from [Releases](https://github.com/daumedia/MikaFileScope/releases).

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
- Sparkle auto-updates with "Check for Updates" menu command
- DMG distribution with build scripts and GitHub Actions CI/CD

## Requirements

- macOS 14.0+ (Sonoma)
- **Apple silicon** — the released build is `arm64` only. Build with
  `bash scripts/build.sh --universal` for a binary that also runs on Intel Macs.
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

> **Set the run destination to “My Mac”.** This is a macOS-only package, but SwiftPM's
> `platforms:` declares a *minimum version*, not a restriction — so Xcode still offers
> iOS destinations. Building for one fails in Sparkle, which ships macOS slices only:
>
> ```
> While building for iOS, no library for this platform was found in Sparkle.xcframework
> ```
>
> Nothing is wrong with the project; switch the destination in the toolbar. If Xcode
> keeps reverting to iOS, delete the project's DerivedData folder — it caches the last
> destination.

## Distribution

### Mac App Store

The store variant needs an Xcode project — a plain SwiftPM package cannot be archived,
and Xcode will not manage certificates for one. It is generated, not committed:

```bash
brew install xcodegen   # once
xcodegen generate       # creates MikaFileScope.xcodeproj from project.yml
open MikaFileScope.xcodeproj
```

In Xcode: select the target, *Signing & Capabilities*, tick **Automatically manage
signing** and pick the team. Xcode then creates the distribution certificate and the
provisioning profile. Product → Archive → Distribute App → App Store Connect.

Both paths share `Sources/` and `Resources/Info.plist`, so version and identifier only
exist once.

### Direct distribution

```bash
# Build .app bundle (direct distribution, with Sparkle)
bash scripts/build.sh

# Mac App Store variant: sandboxed, without Sparkle
bash scripts/build.sh --appstore

# Universal binary (arm64 + x86_64)
bash scripts/build.sh --universal

# Create DMG (requires: brew install create-dmg)
bash scripts/create-dmg.sh

# Simple DMG fallback (no dependencies)
bash scripts/create-dmg-simple.sh
```

Automated releases via GitHub Actions on `v*` tags.

## Website

**[filescope.daumedia.lu](https://filescope.daumedia.lu)**

The marketing landing page lives in [`website/`](website/) — static HTML, CSS and a little vanilla
JS, no build step. Deployed on Vercel with the project's **Root Directory** set to `website`.

```bash
cd website && python3 -m http.server 8080   # local preview
```

See [`website/README.md`](website/README.md) for deployment and how to regenerate the assets.

## License

**Source Available** — see [`LICENSE`](LICENSE).

Using the app is free, including commercially. Reading the source and building it for
your own use is explicitly allowed. Redistribution and derived works require written
permission — this is not an open-source licence.

Copyright 2025 dauMedia / Mika.
