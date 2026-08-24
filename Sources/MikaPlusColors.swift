// MikaPlusColors.swift
// MikaFileScope
//
// Brand color palette for the Mika+ ecosystem.
// Swift 6.0 strict concurrency, macOS 14+

import AppKit
import SwiftUI

extension NSColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var rgb: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&rgb)
        let r = CGFloat((rgb >> 16) & 0xFF) / 255.0
        let g = CGFloat((rgb >> 8) & 0xFF) / 255.0
        let b = CGFloat(rgb & 0xFF) / 255.0
        self.init(srgbRed: r, green: g, blue: b, alpha: 1.0)
    }

    enum MikaPlus {
        static let tealPrimary    = NSColor(hex: "#1D9E75")
        static let tealLight      = NSColor(hex: "#5DCAA5")
        static let tealLightest   = NSColor(hex: "#9FE1CB")
        static let tealSurface    = NSColor(hex: "#E1F5EE")
        static let darkBg         = NSColor(hex: "#1A1A2E")
        static let darkBgDeep     = NSColor(hex: "#0F0F1A")
        static let textPrimary    = NSColor(hex: "#E1F5EE")
        static let textSecondary  = NSColor(hex: "#9FE1CB")
        static let destructive    = NSColor(hex: "#E24B4A")
    }
}

extension Color {
    enum MikaPlus {
        static let tealPrimary   = Color(nsColor: NSColor.MikaPlus.tealPrimary)
        static let tealLight     = Color(nsColor: NSColor.MikaPlus.tealLight)
        static let tealLightest  = Color(nsColor: NSColor.MikaPlus.tealLightest)
        static let tealSurface   = Color(nsColor: NSColor.MikaPlus.tealSurface)
        static let darkBg        = Color(nsColor: NSColor.MikaPlus.darkBg)
        static let darkBgDeep    = Color(nsColor: NSColor.MikaPlus.darkBgDeep)
        static let textPrimary   = Color(nsColor: NSColor.MikaPlus.textPrimary)
        static let textSecondary = Color(nsColor: NSColor.MikaPlus.textSecondary)
        static let destructive   = Color(nsColor: NSColor.MikaPlus.destructive)

        /// Diagrammpalette, abgeleitet aus der Markenfarbe.
        ///
        /// Der erste Eintrag **ist** `tealPrimary` (#1D9E75) — zuvor begann die Palette
        /// bei 148° mit abweichender Sättigung und Helligkeit und traf die Markenfarbe
        /// damit nicht. Die übrigen sieben rotieren im Farbkreis um je 45°, mit den
        /// Werten der Markenfarbe für Sättigung und Helligkeit.
        static let chartPalette: [Color] = {
            let base = NSColor.MikaPlus.tealPrimary.usingColorSpace(.deviceRGB)
            let hue = Double(base?.hueComponent ?? 0.447)
            let sat = Double(base?.saturationComponent ?? 0.82)
            let bri = Double(base?.brightnessComponent ?? 0.62)
            return (0..<8).map { i in
                Color(
                    hue: (hue + Double(i) * (45.0 / 360.0)).truncatingRemainder(dividingBy: 1.0),
                    saturation: sat,
                    brightness: bri
                )
            }
        }()

        /// Farbe für ein Altersfenster: je älter, desto entsättigter und dunkler.
        /// Einzige Quelle für den Verlauf der Zeitachse.
        static func ageColor(step: Int, of total: Int) -> Color {
            let base = NSColor.MikaPlus.tealPrimary.usingColorSpace(.deviceRGB)
            let progress = total > 0 ? Double(step) / Double(total) : 0
            return Color(
                hue: Double(base?.hueComponent ?? 0.447),
                saturation: Double(base?.saturationComponent ?? 0.82) * (1.0 - progress * 0.6),
                brightness: Double(base?.brightnessComponent ?? 0.62) * (1.0 - progress * 0.3) + progress * 0.15
            )
        }

        /// Farbe für einen Rang in der Größenreihenfolge.
        ///
        /// Jenseits der Palette wird weiter rotiert statt auf Grau auszuweichen: Grau
        /// ist in den Diagrammen der Sammelposten „Other" und darf nicht zugleich
        /// „keine Farbe mehr übrig" bedeuten.
        static func chartColor(rank: Int) -> Color {
            guard rank >= 0, rank != Int.max else { return .gray }
            if rank < chartPalette.count { return chartPalette[rank] }
            let base = NSColor.MikaPlus.tealPrimary.usingColorSpace(.deviceRGB)
            let hue = Double(base?.hueComponent ?? 0.447)
            let sat = Double(base?.saturationComponent ?? 0.82)
            let bri = Double(base?.brightnessComponent ?? 0.62)
            // Zwischentöne: versetzt um die halbe Schrittweite, leicht abgedunkelt.
            let round = rank / chartPalette.count
            let offset = Double(rank % chartPalette.count) * (45.0 / 360.0)
                + Double(round) * (22.5 / 360.0)
            return Color(
                hue: (hue + offset).truncatingRemainder(dividingBy: 1.0),
                saturation: max(0.35, sat - Double(round) * 0.12),
                brightness: min(0.92, bri + Double(round) * 0.08)
            )
        }
    }
}
