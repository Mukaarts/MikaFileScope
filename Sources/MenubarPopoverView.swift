// MenubarPopoverView.swift
// MikaFileScope

import SwiftUI

struct MenubarPopoverView: View {
    let engine: ScanEngine

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
                miniStat(value: "\(engine.totalFiles)", label: "Files")
                miniStat(value: formattedSize, label: "Total")
                miniStat(value: "\(engine.groups.count)", label: "Types")
            }

            if !engine.groups.isEmpty {
                Divider()
                VStack(alignment: .leading, spacing: 4) {
                    let topGroups = engine.groups.sorted { $0.totalBytes > $1.totalBytes }.prefix(5)
                    ForEach(Array(topGroups)) { group in
                        HStack {
                            Text(group.displayExt)
                                .font(.caption)
                                .frame(width: 60, alignment: .leading)
                            ProgressView(value: group.percentage(of: engine.totalSize), total: 100)
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

    private var formattedSize: String {
        ByteCountFormatter().string(fromByteCount: engine.totalSize)
    }
}
