// ContentView.swift
// MikaFileScope

import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var engine = ScanEngine()
    @State private var selectedTab: Tab = .list
    @State private var sortOrder = [KeyPathComparator(\FileTypeGroup.count, order: .reverse)]
    @State private var isDropTargeted = false

    enum Tab: String, CaseIterable {
        case list = "List"
        case charts = "Charts"
        case timeline = "Timeline"
    }

    var body: some View {
        VStack(spacing: 0) {
            if engine.scannedFolderURL == nil && !engine.isScanning {
                emptyState
            } else {
                summaryBar
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)

                categoryBar

                Divider()

                tabSwitcher
                    .padding(.top, 12)

                if engine.filteredGroups.isEmpty && !engine.isScanning {
                    noMatchState
                } else {
                    mainContent
                }
            }
        }
        .frame(minWidth: 800, minHeight: 600)
        .background(.background)
        .navigationTitle("FileScope")
        .toolbar {
            toolbarContent
        }
        .alert("Scan Error", isPresented: .init(
            get: { engine.errorMessage != nil },
            set: { if !$0 { engine.errorMessage = nil } }
        )) {
            Button("OK") { engine.errorMessage = nil }
        } message: {
            Text(engine.errorMessage ?? "")
        }
        .onDrop(of: [.fileURL], isTargeted: $isDropTargeted) { providers in
            handleDrop(providers: providers)
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .automatic) {
            Button {
                chooseFolder()
            } label: {
                Label("Choose Folder", systemImage: "folder.badge.plus")
            }
            .buttonStyle(.bordered)
            .tint(Color.MikaPlus.tealPrimary)

            if let url = engine.scannedFolderURL {
                Text(url.lastPathComponent)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .help(url.path)
            }

            Button {
                engine.rescan()
            } label: {
                Label("Rescan", systemImage: "arrow.clockwise")
            }
            .disabled(engine.scannedFolderURL == nil || engine.isScanning)

            Toggle(isOn: Binding(
                get: { engine.includeHidden },
                set: { newValue in
                    engine.includeHidden = newValue
                    if engine.scannedFolderURL != nil {
                        engine.rescan()
                    }
                }
            )) {
                Label("Hidden Files", systemImage: "eye.slash")
            }
            .toggleStyle(.switch)
            .controlSize(.small)

            Menu {
                Button("Export CSV") {
                    ExportManager.exportCSV(
                        groups: engine.filteredGroups,
                        totalSize: engine.filteredTotalSize,
                        folderURL: engine.scannedFolderURL
                    )
                }
                Button("Export JSON") {
                    ExportManager.exportJSON(
                        groups: engine.filteredGroups,
                        totalFiles: engine.filteredTotalFiles,
                        totalSize: engine.filteredTotalSize,
                        folderURL: engine.scannedFolderURL
                    )
                }
            } label: {
                Label("Export", systemImage: "square.and.arrow.up")
            }
            .disabled(engine.filteredGroups.isEmpty)

            if engine.isScanning {
                ProgressView()
                    .controlSize(.small)
            }
        }
    }

    // MARK: - Summary Bar

    private var summaryBar: some View {
        HStack(spacing: 16) {
            StatPill(label: "Files", value: "\(engine.filteredTotalFiles)")
            StatPill(label: "Total Size", value: formattedTotalSize)
            StatPill(label: "Types", value: "\(engine.filteredGroups.count)")
            Spacer()
        }
    }

    private var formattedTotalSize: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: engine.filteredTotalSize)
    }

    // MARK: - Category Bar

    private var categoryBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(FileCategory.allCases) { category in
                    Button {
                        engine.selectedCategory = category
                    } label: {
                        Label(category.rawValue, systemImage: category.icon)
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                engine.selectedCategory == category
                                    ? Color.MikaPlus.tealPrimary.opacity(0.2)
                                    : Color.secondary.opacity(0.1),
                                in: Capsule()
                            )
                            .foregroundStyle(
                                engine.selectedCategory == category
                                    ? Color.MikaPlus.tealPrimary
                                    : .secondary
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 6)
    }

    // MARK: - Tab Switcher

    private var tabSwitcher: some View {
        Picker("View", selection: $selectedTab) {
            ForEach(Tab.allCases, id: \.self) { tab in
                Text(tab.rawValue).tag(tab)
            }
        }
        .pickerStyle(.segmented)
        .frame(width: 300)
    }

    // MARK: - Main Content

    @ViewBuilder
    private var mainContent: some View {
        switch selectedTab {
        case .list:
            listTab
        case .charts:
            ChartView(groups: engine.filteredGroups, totalSize: engine.filteredTotalSize)
        case .timeline:
            HistogramView(dateBuckets: engine.dateBuckets)
        }
    }

    private var listTab: some View {
        Table(engine.filteredGroups, sortOrder: $sortOrder) {
            TableColumn("Extension", value: \.ext) { group in
                HStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(colorForGroup(group))
                        .frame(width: 4, height: 18)
                    Text(group.displayExt)
                        .font(.system(.body, design: .monospaced))
                }
            }
            .width(min: 120, ideal: 160)

            TableColumn("Count", value: \.count) { group in
                Text("\(group.count)")
                    .monospacedDigit()
            }
            .width(min: 60, ideal: 80)

            TableColumn("Size", value: \.totalBytes) { group in
                Text(group.formattedSize)
                    .monospacedDigit()
            }
            .width(min: 80, ideal: 120)

            TableColumn("% of Total") { group in
                let pct = group.percentage(of: engine.filteredTotalSize)
                HStack(spacing: 8) {
                    ProgressView(value: pct, total: 100)
                        .tint(Color.MikaPlus.tealPrimary)
                        .frame(width: 60)
                    Text(String(format: "%.1f%%", pct))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
            }
            .width(min: 120, ideal: 160)
        }
        .onChange(of: sortOrder) { _, newOrder in
            engine.groups.sort(using: newOrder)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "folder.badge.questionmark")
                .font(.system(size: 56))
                .foregroundStyle(isDropTargeted ? Color.MikaPlus.tealPrimary : .secondary)

            Text("Drop a folder here or click Choose Folder")
                .font(.title3)
                .foregroundStyle(.secondary)

            Button("Choose Folder") {
                chooseFolder()
            }
            .buttonStyle(.bordered)
            .tint(Color.MikaPlus.tealPrimary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    isDropTargeted ? Color.MikaPlus.tealPrimary : Color.clear,
                    style: StrokeStyle(lineWidth: 2, dash: [8])
                )
                .padding(20)
        )
    }

    private var noMatchState: some View {
        VStack(spacing: 12) {
            Image(systemName: "line.3.horizontal.decrease.circle")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text("No files match this category")
                .font(.title3)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Actions

    private func chooseFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "Choose a folder to scan"

        if panel.runModal() == .OK, let url = panel.url {
            engine.scan(folder: url)
        }
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { data, _ in
            guard let data = data as? Data,
                  let urlString = String(data: data, encoding: .utf8),
                  let url = URL(string: urlString) else { return }

            var isDir: ObjCBool = false
            guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir),
                  isDir.boolValue else { return }

            DispatchQueue.main.async {
                engine.scan(folder: url)
            }
        }
        return true
    }

    private func colorForGroup(_ group: FileTypeGroup) -> Color {
        let palette = Color.MikaPlus.chartPalette
        let sorted = engine.filteredGroups.sorted { $0.totalBytes > $1.totalBytes }
        if let index = sorted.firstIndex(where: { $0.id == group.id }), index < palette.count {
            return palette[index]
        }
        return .gray
    }
}

// MARK: - StatPill

private struct StatPill: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(.title3, design: .default).monospacedDigit().bold())
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
    }
}
