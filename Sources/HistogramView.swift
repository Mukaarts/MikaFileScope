// HistogramView.swift
// MikaFileScope

import Charts
import SwiftUI

struct HistogramView: View {
    let dateBuckets: [DateBucket]

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                Text("File Age Distribution")
                    .font(.headline)

                if dateBuckets.isEmpty {
                    Text("No date information available")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, minHeight: 200)
                } else {
                    fileCountChart
                    Divider()
                    sizeChart
                }
            }
            .padding(24)
        }
    }

    private var fileCountChart: some View {
        VStack(spacing: 12) {
            Text("File Count by Age")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Chart(dateBuckets) { bucket in
                BarMark(
                    x: .value("Period", bucket.label),
                    y: .value("Files", bucket.fileCount)
                )
                .foregroundStyle(gradientColor(for: bucket.sortIndex))
                .cornerRadius(4)
            }
            .chartXAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                        .font(.caption2)
                }
            }
            .frame(height: 220)
        }
    }

    private var sizeChart: some View {
        VStack(spacing: 12) {
            Text("Total Size by Age")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Chart(dateBuckets) { bucket in
                BarMark(
                    x: .value("Period", bucket.label),
                    y: .value("Size", bucket.totalBytes)
                )
                .foregroundStyle(gradientColor(for: bucket.sortIndex))
                .cornerRadius(4)
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let bytes = value.as(Int64.self) {
                            Text(ByteCountFormatter().string(fromByteCount: bytes))
                                .font(.caption2)
                        }
                    }
                }
            }
            .frame(height: 220)
        }
    }

    private func gradientColor(for sortIndex: Int) -> Color {
        let progress = Double(sortIndex) / 6.0
        return Color(
            hue: 148.0 / 360.0,
            saturation: 0.70 * (1.0 - progress * 0.6),
            brightness: 0.75 * (1.0 - progress * 0.3)
        )
    }
}
