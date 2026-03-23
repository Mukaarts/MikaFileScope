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
            Text("Scanning for duplicates...")
                .foregroundStyle(.secondary)
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var noDuplicatesView: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 40))
                .foregroundStyle(Color.MikaPlus.tealPrimary)
            Text("No duplicate files found")
                .font(.title3)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var resultsList: some View {
        VStack(spacing: 0) {
            Text("FileScope does not delete files. Use Reveal in Finder to review manually.")
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
