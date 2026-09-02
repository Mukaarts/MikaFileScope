// AccessIntroView.swift
// MikaFileScope
//
// Die einmalige Erklärung vor dem ersten Ordnerzugriff. Sie kündigt an, dass gleich
// Systemdialoge kommen, und sagt vorher, was gelesen wird und was nicht. Ohne diese
// Ankündigung standen die TCC-Abfragen zusammenhanglos im Raum — Ablehnungsgrund
// 5.1.1(ii) am 2026-09-01. Der Wortlaut steht in `AccessIntro`.

import SwiftUI

struct AccessIntroView: View {
    /// Wird nach dem Schließen aufgerufen — dann folgt der Ordnerdialog oder der
    /// Scan des abgelegten Ordners.
    var onContinue: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                Text(AccessIntro.title)
                    .font(.title2.bold())
                Text(AccessIntro.subtitle)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 20)

            VStack(alignment: .leading, spacing: 18) {
                ForEach(AccessIntro.points, id: \.headline) { point in
                    HStack(alignment: .top, spacing: 14) {
                        Image(systemName: point.symbol)
                            .font(.system(size: 18))
                            .foregroundStyle(Color.MikaPlus.tealPrimary)
                            .frame(width: 26)
                            .accessibilityHidden(true)

                        VStack(alignment: .leading, spacing: 3) {
                            Text(point.headline)
                                .font(.headline)
                            Text(point.detail)
                                .font(.callout)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .accessibilityElement(children: .combine)
                }
            }
            .padding(.horizontal, 24)

            Spacer(minLength: 24)

            Divider()

            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("Choose Folder\u{2026}") {
                    dismiss()
                    onContinue()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
                .tint(Color.MikaPlus.tealPrimary)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
        .frame(width: 520)
        .fixedSize(horizontal: false, vertical: true)
    }
}
