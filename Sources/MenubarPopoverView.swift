// MenubarPopoverView.swift
// MikaFileScope

import AppKit
import SwiftUI

struct MenubarPopoverView: View {
    let engine: ScanEngine
    @AppStorage(AppStorageKeys.accessIntroSeen) private var accessIntroSeen = false

    var body: some View {
        VStack(spacing: 0) {
            headerView
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 10)

            Divider()

            if engine.scannedFolderURL != nil {
                scanSummary
                    .padding(16)
            } else {
                noScanView
                    .padding(16)
            }

            Divider()

            footerView
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
        }
        .frame(width: 280)
    }

    private var headerView: some View {
        HStack(spacing: 8) {
            Image(systemName: "doc.viewfinder")
                .font(.system(size: 16))
                .foregroundStyle(Color.MikaPlus.tealPrimary)
            Text("Mika+FileScope")
                .font(.system(size: 14, weight: .semibold))
            Spacer()
            if engine.isScanning {
                ProgressView()
                    .controlSize(.small)
            }
        }
    }

    private var noScanView: some View {
        VStack(spacing: 8) {
            Image(systemName: "folder.badge.questionmark")
                .font(.system(size: 28))
                .foregroundStyle(.secondary)
            Text("No folder scanned")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    private var scanSummary: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let url = engine.scannedFolderURL {
                Text(url.lastPathComponent)
                    .font(.system(size: 12, weight: .medium))
                    .lineLimit(1)
                    .help(url.path)
            }

            HStack(spacing: 16) {
                miniStat(value: "\(engine.filteredTotalFiles)", label: "Files")
                miniStat(value: formattedSize, label: "Total")
                miniStat(value: "\(engine.filteredGroups.count)", label: "Types")
            }

            if !engine.filteredGroups.isEmpty {
                Divider()
                VStack(alignment: .leading, spacing: 4) {
                    let topGroups = engine.filteredGroups.sorted { $0.totalBytes > $1.totalBytes }.prefix(5)
                    ForEach(Array(topGroups)) { group in
                        HStack {
                            Text(group.displayExt)
                                .font(.caption)
                                .frame(width: 60, alignment: .leading)
                            ProgressView(value: group.percentage(of: engine.filteredTotalSize), total: 100)
                                .tint(Color.MikaPlus.tealPrimary)
                            Text(group.formattedSize)
                                .font(.caption2)
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }

    private func miniStat(value: String, label: String) -> some View {
        VStack(alignment: .leading) {
            Text(value)
                .font(.system(.body, design: .default).monospacedDigit().bold())
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private var footerView: some View {
        HStack {
            // Ohne diesen Weg konnte der beworbene „Quick Scan" nichts scannen:
            // Ein Ordner ließ sich nur im Hauptfenster wählen.
            Button("Folder\u{2026}") {
                requestFolder()
            }
            .buttonStyle(.plain)
            .font(.system(size: 11))
            .foregroundStyle(.secondary)
            .disabled(engine.isScanning)

            Button("Rescan") {
                engine.rescan()
            }
            .buttonStyle(.plain)
            .font(.system(size: 11))
            .foregroundStyle(.secondary)
            .disabled(engine.scannedFolderURL == nil || engine.isScanning)

            Spacer()

            Button("Quit") {
                NSApp.terminate(nil)
            }
            .buttonStyle(.plain)
            .font(.system(size: 11))
            .foregroundStyle(.secondary)
        }
    }

    /// Beim ersten Mal erst erklären, danach direkt auswählen. Im Popover lässt sich
    /// kein Blatt zeigen, deshalb kommt die Erklärung hier als eigenes Fenster —
    /// derselbe Wortlaut wie im Hauptfenster, siehe `AccessIntro`.
    private func requestFolder() {
        guard accessIntroSeen else {
            guard FolderPicker.confirmIntroModally() else { return }
            accessIntroSeen = true
            FolderPicker.choose(engine: engine)
            return
        }
        FolderPicker.choose(engine: engine)
    }

    private var formattedSize: String {
        ByteCountFormatter().string(fromByteCount: engine.filteredTotalSize)
    }
}
