// DuplicateResultView.swift
// MikaFileScope

import AppKit
import SwiftUI

struct DuplicateResultView: View {
    let detector: DuplicateDetector
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()

            if detector.isDetecting {
                progressSection
            } else if detector.duplicateGroups.isEmpty {
                noDuplicatesView
            } else {
                resultsList
            }
        }
        .frame(minWidth: 600, maxWidth: 600, minHeight: 400, maxHeight: 700)
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Duplicate Files")
                    .font(.headline)
                if !detector.duplicateGroups.isEmpty {
                    Text("\(detector.duplicateGroups.count) groups \u{2022} \(formattedWasted) recoverable")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Button("Done") { dismiss() }
                .buttonStyle(.bordered)
        }
        .padding()
    }

    private var progressSection: some View {
        VStack(spacing: 16) {
            ProgressView(value: detector.progress)
                .progressViewStyle(.linear)
                .tint(Color.MikaPlus.tealPrimary)
                .accessibilityLabel("Duplicate search progress")
                .accessibilityValue("\(Int(detector.progress * 100)) percent")
            Text("Scanning for duplicates… \(Int(detector.progress * 100)) %")
                .foregroundStyle(.secondary)
                .monospacedDigit()
            Button("Cancel") { detector.cancel() }
                .buttonStyle(.bordered)
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var noDuplicatesView: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 40))
                .foregroundStyle(Color.MikaPlus.tealPrimary)
                .accessibilityHidden(true)
            Text("No duplicate files found")
                .font(.title3)
                .foregroundStyle(.secondary)
            skippedHint
            unreadableHint
            Text("FileScope does not delete files.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// Macht sichtbar, dass kleine Dateien gar nicht geprüft wurden — sonst liest sich
    /// „keine Duplikate gefunden" als „es gibt keine".
    /// Ein verweigerter Zugriff darf nicht als „nichts gefunden" durchgehen.
    @ViewBuilder
    private var unreadableHint: some View {
        if detector.unreadable > 0 {
            Text("\(detector.unreadable) file(s) could not be opened and were not compared. "
                 + "If macOS denied access, you can grant it in System Settings \u{203A} Privacy & Security \u{203A} Files and Folders.")
                .font(.caption)
                .foregroundStyle(Color.MikaPlus.destructive)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private var skippedHint: some View {
        if detector.skippedTooSmall > 0 {
            Text("\(detector.skippedTooSmall) file(s) below \(ByteCountFormatter().string(fromByteCount: DuplicateDetector.minimumSize)) were not compared")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var resultsList: some View {
        VStack(spacing: 0) {
            VStack(spacing: 4) {
                Text("FileScope does not delete files. Use Reveal in Finder to review manually.")
                skippedHint
                unreadableHint
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.horizontal)
            .padding(.top, 8)

            List {
                ForEach(detector.duplicateGroups) { group in
                    Section {
                        ForEach(group.urls, id: \.self) { url in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(url.lastPathComponent)
                                        .font(.system(.body, design: .monospaced))
                                    Text(url.deletingLastPathComponent().path)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                }
                                Spacer()
                                Button {
                                    NSWorkspace.shared.activateFileViewerSelecting([url])
                                } label: {
                                    Image(systemName: "magnifyingglass")
                                }
                                .buttonStyle(.borderless)
                                .help("Reveal in Finder")
                            }
                        }
                    } header: {
                        HStack {
                            Text("\(group.urls.count) copies")
                            Spacer()
                            Text(group.formattedSize)
                                .foregroundStyle(.secondary)
                            Text("(\(ByteCountFormatter().string(fromByteCount: group.wastedBytes)) wasted)")
                                .foregroundStyle(Color.MikaPlus.destructive)
                        }
                    }
                }
            }
        }
    }

    private var formattedWasted: String {
        ByteCountFormatter().string(fromByteCount: detector.totalWastedBytes)
    }
}
