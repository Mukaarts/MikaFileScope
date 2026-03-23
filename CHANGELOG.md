# Changelog

All notable changes to Mika+FileScope will be documented in this file.

Format based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added
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
