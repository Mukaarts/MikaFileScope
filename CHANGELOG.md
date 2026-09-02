# Changelog

All notable changes to Mika+FileScope will be documented in this file.

Format based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [2.1.1] - 2026-09-02

Repariert die beiden Beanstandungen aus dem App Review vom 2026-09-01
(Submission 9b246573-21ad-44c4-a5a5-db0ac143b21c).

### Fixed
- **Guideline 5.1.1(ii)** — the app carried no purpose strings at all, so the macOS
  consent dialogs for Desktop, Documents and Downloads appeared with no text. Six
  `NS*UsageDescription` keys now explain what is read, what for, and what is not
- **Guideline 2.1(a)** — the export did nothing. The App Store build was signed with
  `files.user-selected.read-only`, and without the read-write entitlement the Powerbox
  never opens the save dialog at all — no sheet, no file, no error. Verified on
  2026-09-02 by signing the same build both ways
- The save dialog is now presented as a sheet instead of `runModal()` from inside a
  SwiftUI menu action, where a nested modal session could fail to appear
- Scan progress stood still at 0: `performScan` is `nonisolated` and never reached
  `scannedSoFar`. A long scan was indistinguishable from a frozen app
- Cancelling a scan or a duplicate search left the background work running — a
  detached task does not inherit its creator's cancellation
- The duplicate search read files without a security scope, so after a restart it
  silently reported "no duplicates" instead of saying it could not open anything

### Added
- One-time explanation before the first folder access: it announces the system
  prompts and states that only names, sizes and dates are read
- `File > Export as CSV…` (Cmd-E) and `Export as JSON…` (Shift-Cmd-E) as a second
  route to the export, independent of the toolbar
- `Tests/BundleConfigTests` — asserts the purpose strings and the store entitlements,
  so this rejection cannot recur unnoticed

### Changed
- Version 2.1.1; `CFBundleShortVersionString` and `CFBundleVersion` stay equal
- The interface is English throughout — the German fragments in the progress display,
  the menu, the duplicate sheet and the accessibility labels are gone
- Denied access is now named as such, with the path to System Settings, instead of
  being counted silently

## [Unreleased]

### Added
- Mac App Store variant: `bash scripts/build.sh --appstore` builds a sandboxed bundle
  without Sparkle (`APPSTORE=1` in `Package.swift` drops the dependency entirely)
- Security-scoped bookmark of the last scanned folder — “Rescan” now survives a restart
- Universal binary via `bash scripts/build.sh --universal` (arm64 + x86_64)
- Cancel button for both the folder scan and the duplicate search
- Real progress percentage in the duplicate search, and a note when files were skipped
  for being below the 1 KB threshold
- Warning when files could not be read during a scan — the totals are then incomplete
- Folder picker in the menu bar popover, so the quick scan can actually scan
- Accessibility labels for the table, both charts and the age timeline
- `LICENSE` (Source Available), privacy policy and imprint on the website
- 28 tests covering the update channel, file categories, age buckets and both exporters
- CI workflow: builds both variants, verifies the App Store build contains no Sparkle

### Changed
- Packages (`.app`, `.rtfd`, …) count as one object instead of exposing their contents
- Symbolic links are no longer counted as separate files
- Hardlinks are recognised as the same data and no longer reported as duplicates
- The duplicate finder and the menu bar summary now follow the category filter
- Chart palette starts at the brand colour; grey is reserved for the “Other” bucket
- The category filter resets when a different folder is scanned
- `.ts` belongs to Videos only (was in Videos *and* Code)
- `scannedAt` in the JSON export is the scan time, not the export time
- Percentages in the JSON export no longer carry floating-point artefacts
- `CFBundleVersion` raised to 2 — Sparkle compares it, and it had been stuck at 1
- Update feed points at `main`; `appcast.xml` carries a signed entry for v2.0.0
- `build.sh` verifies the signature, drops `--deep`, and cleans a stale build cache

### Fixed
- The update feed was empty, so no installed copy could ever learn about a new version
- The feed URL could be redirected by any local process writing to user defaults
- A failed JSON export silently wrote `{}` instead of reporting the error
- Read errors during a scan were swallowed, leaving totals quietly too low
- Two scans could run at once and overwrite each other's results

### Removed
- Grey as a colour for the ninth and further file types in the table
- Marketing landing page in `website/` — static HTML/CSS, no build step, deployable on Vercel with
  root directory `website`
- Real app screenshots (List, Charts, Timeline, Duplicates) captured in Dark Mode and served as WebP
- `scripts/GenerateOGImage.swift` — renders the 1200×630 social preview from the app icon via AppKit
- Landing page states the ad-hoc signature and the resulting first-launch step explicitly, plus the
  Apple silicon requirement
- Toggle to include/exclude hidden files (dotfiles, .DS_Store, etc.) in scans
- Auto-rescan when hidden files toggle is changed
- File category filter (All, Images, Documents, Videos, Audio, Code, Archives, Other)
- Category chip bar with teal-highlighted active category
- "No files match this category" empty state for filtered views
- Summary bar, export, and charts now reflect filtered data
- Timeline tab with file age distribution histogram (file count + size by age)
- Date buckets: Today, Past Week, Past Month, Past 3 Months, Past Year, Older
- Teal-to-gray gradient coloring based on file recency
- Duplicate file detection via SHA-256 hashing (streaming, 1 MB chunks)
- Duplicate results sheet with file count, wasted space, and Reveal in Finder
- Files grouped by size first, then hashed for efficiency (skips files < 1 KB)
- Optional menubar quick-scan mode with compact popover (top 5 types, stats)
- Menubar toggle in toolbar to show/hide menubar icon
- App stays running when menubar mode is active and window is closed
- Sparkle auto-update integration with "Check for Updates" menu command
- Info.plist with app metadata and Sparkle feed URL (GitHub raw/master)
- DMG distribution with build scripts (build.sh, create-dmg.sh, create-dmg-simple.sh)
- DMG background generator with Mika+ branding (dark navy + teal accents)
- GitHub Actions CI/CD workflow for automated releases on version tags
- Code signing entitlements for hardened runtime

## [1.0.0] - 2026-03-23

### Added
- Recursive folder scanning with file type grouping by extension
- Sortable table view (extension, count, size, percentage of total)
- Donut chart and horizontal bar chart via Swift Charts (top 8 types + "Other")
- CSV export with human-readable sizes and percentages
- JSON export with metadata (folder path, timestamp, totals)
- Drag-and-drop folder support on the main window
- Folder picker via NSOpenPanel
- Rescan button for re-scanning the same folder
- Non-blocking background scanning (UI stays responsive for large folders)
- Dark and Light mode support
- Summary bar showing total files, total size, and number of distinct types
- 8-color chart palette derived from Mika+ teal (#1D9E75) via hue rotation
