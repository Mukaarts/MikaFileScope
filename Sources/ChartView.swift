// ChartView.swift
// MikaFileScope

import Charts
import SwiftUI

struct ChartItem: Identifiable {
    let id: String
    let label: String
    let bytes: Int64
    let count: Int
    let color: Color

    var formattedSize: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

struct ChartView: View {
    let groups: [FileTypeGroup]
    let totalSize: Int64

    private var chartData: [ChartItem] {
        let sorted = groups.sorted { $0.totalBytes > $1.totalBytes }
        let palette = Color.MikaPlus.chartPalette
        let top = sorted.prefix(8)
        let rest = sorted.dropFirst(8)

        var items = top.enumerated().map { i, group in
            ChartItem(
                id: group.ext.isEmpty ? "no-ext" : group.ext,
                label: group.displayExt,
                bytes: group.totalBytes,
                count: group.count,
                color: palette[i]
            )
        }

        if !rest.isEmpty {
            let otherBytes = rest.reduce(Int64(0)) { $0 + $1.totalBytes }
            let otherCount = rest.reduce(0) { $0 + $1.count }
            items.append(ChartItem(
                id: "other",
                label: "Other",
                bytes: otherBytes,
                count: otherCount,
                color: .gray
            ))
        }

        return items
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                donutSection
                Divider()
                barSection
            }
            .padding(24)
        }
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: groups.map(\.id))
    }

    // MARK: - Donut Chart

    private var donutSection: some View {
        VStack(spacing: 16) {
            Text("Distribution by Size")
                .font(.headline)

            HStack(alignment: .top, spacing: 32) {
                Chart(chartData) { item in
                    SectorMark(
                        angle: .value("Size", item.bytes),
                        innerRadius: .ratio(0.5),
                        angularInset: 1.5
                    )
                    .foregroundStyle(item.color)
                    .cornerRadius(4)
                }
                .frame(width: 260, height: 260)

                legend
            }
        }
    }

    private var legend: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(chartData) { item in
                HStack(spacing: 8) {
                    Circle()
                        .fill(item.color)
                        .frame(width: 10, height: 10)
                    Text(item.label)
                        .font(.caption)
                        .lineLimit(1)
                    Spacer()
                    Text(item.formattedSize)
                        .font(.caption)
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(minWidth: 180)
    }

    // MARK: - Bar Chart

    private var barSection: some View {
        VStack(spacing: 16) {
            Text("Top File Types by Size")
                .font(.headline)

            Chart(chartData) { item in
                BarMark(
                    x: .value("Size", item.bytes),
                    y: .value("Type", item.label)
                )
                .foregroundStyle(item.color)
                .cornerRadius(4)
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let bytes = value.as(Int64.self) {
                            let formatter = ByteCountFormatter()
                            Text(formatter.string(fromByteCount: bytes))
                                .font(.caption2)
                        }
                    }
                }
            }
            .frame(height: CGFloat(chartData.count) * 36 + 20)
        }
    }
}
