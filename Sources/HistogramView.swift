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
            .accessibilityLabel("Dateianzahl nach Alter")
            .accessibilityValue(dateBuckets.map { "\($0.label): \($0.fileCount)" }.joined(separator: ", "))
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
            .accessibilityLabel("Gesamtgröße nach Alter")
            .accessibilityValue(dateBuckets.map { "\($0.label): \(ByteCountFormatter().string(fromByteCount: $0.totalBytes))" }.joined(separator: ", "))
        }
    }

    /// Verlauf von der Markenfarbe (jung) zu entsättigtem Grau (alt).
    /// Die Werte stammen aus `MikaPlusColors` — zuvor standen sie hier ein zweites Mal
    /// fest im Code, sodass eine Änderung der Markenfarbe die Zeitachse nicht erreichte.
    private func gradientColor(for sortIndex: Int) -> Color {
        Color.MikaPlus.ageColor(step: sortIndex, of: 6)
    }
}
