#!/usr/bin/env swift
// GenerateIcon.swift
// MikaFileScope
//
// Generates AppIcon.icns — dark background with magnifying glass over
// file grid, teal accent, M+ badge. Matches Mika+ ecosystem style.
// Usage: swift scripts/GenerateIcon.swift

import AppKit
import CoreGraphics
import Foundation

// MARK: - Color Helpers

func color(hex: String) -> NSColor {
    let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
    var rgb: UInt64 = 0
    Scanner(string: hex).scanHexInt64(&rgb)
    let r = CGFloat((rgb >> 16) & 0xFF) / 255.0
    let g = CGFloat((rgb >> 8) & 0xFF) / 255.0
    let b = CGFloat(rgb & 0xFF) / 255.0
    return NSColor(srgbRed: r, green: g, blue: b, alpha: 1.0)
}

let tealPrimary = color(hex: "#1D9E75")
let tealLight = color(hex: "#5DCAA5")
let tealLightest = color(hex: "#9FE1CB")
let darkBg = color(hex: "#1A1A2E")
let darkBgDeep = color(hex: "#0F0F1A")

// MARK: - App Icon Generator

func generateAppIcon(size: Int) -> NSImage {
    let s = CGFloat(size)
    let image = NSImage(size: NSSize(width: s, height: s))
    image.lockFocus()

    guard let ctx = NSGraphicsContext.current?.cgContext else {
        image.unlockFocus()
        return image
    }

    let colorSpace = CGColorSpaceCreateDeviceRGB()

    // Background gradient — superellipse mask
    let cornerRadius = s * 0.22
    let rect = CGRect(x: 0, y: 0, width: s, height: s)
    let bgPath = CGPath(roundedRect: rect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
    ctx.addPath(bgPath)
    ctx.clip()

    let bgColors = [darkBgDeep.cgColor, darkBg.cgColor] as CFArray
    let bgGrad = CGGradient(colorsSpace: colorSpace, colors: bgColors, locations: [0, 1])!
    ctx.drawLinearGradient(bgGrad, start: CGPoint(x: s / 2, y: s), end: CGPoint(x: s / 2, y: 0), options: [])

    // Subtle grid dots — file/folder motif
    ctx.setFillColor(tealPrimary.withAlphaComponent(0.06).cgColor)
    let dotSpacing = s * 0.065
    let dotRadius = s * 0.006
    for col in 0..<Int(s / dotSpacing) {
        for row in 0..<Int(s / dotSpacing) {
            let x = CGFloat(col) * dotSpacing + dotSpacing / 2
            let y = CGFloat(row) * dotSpacing + dotSpacing / 2
            ctx.fillEllipse(in: CGRect(x: x - dotRadius, y: y - dotRadius, width: dotRadius * 2, height: dotRadius * 2))
        }
    }

    // --- File bars (representing file type list) ---
    let barsX = s * 0.18
    let barsY = s * 0.28
    let barsWidth = s * 0.45
    let barHeight = s * 0.045
    let barSpacing = s * 0.075
    let barCorner = s * 0.012

    let barWidths: [CGFloat] = [1.0, 0.7, 0.85, 0.55, 0.4]
    for (i, widthFraction) in barWidths.enumerated() {
        let y = barsY + CGFloat(i) * barSpacing
        let w = barsWidth * widthFraction
        let alpha = 0.35 - Double(i) * 0.05
        let barRect = CGRect(x: barsX, y: y, width: w, height: barHeight)
        let barPath = CGPath(roundedRect: barRect, cornerWidth: barCorner, cornerHeight: barCorner, transform: nil)
        ctx.addPath(barPath)
        ctx.setFillColor(tealLight.withAlphaComponent(alpha).cgColor)
        ctx.fillPath()

        // Small colored dot at start of each bar
        let dotSize = barHeight * 0.7
        let dotY = y + (barHeight - dotSize) / 2
        let hue = (148.0 + Double(i) * 45.0) / 360.0
        let dotColor = NSColor(hue: hue, saturation: 0.7, brightness: 0.75, alpha: CGFloat(alpha + 0.2))
        ctx.setFillColor(dotColor.cgColor)
        ctx.fillEllipse(in: CGRect(x: barsX - dotSize * 1.5, y: dotY, width: dotSize, height: dotSize))
    }

    // --- Magnifying glass ---
    let lensCenter = CGPoint(x: s * 0.6, y: s * 0.55)
    let lensRadius = s * 0.2
    let handleLength = s * 0.16
    let handleWidth = s * 0.055

    // Lens glow (outer)
    ctx.setFillColor(tealPrimary.withAlphaComponent(0.1).cgColor)
    ctx.fillEllipse(in: CGRect(
        x: lensCenter.x - lensRadius * 1.3,
        y: lensCenter.y - lensRadius * 1.3,
        width: lensRadius * 2.6,
        height: lensRadius * 2.6
    ))

    // Lens glass — gradient fill
    ctx.saveGState()
    let lensRect = CGRect(x: lensCenter.x - lensRadius, y: lensCenter.y - lensRadius, width: lensRadius * 2, height: lensRadius * 2)
    ctx.addEllipse(in: lensRect)
    ctx.clip()
    let glassColors = [
        tealPrimary.withAlphaComponent(0.15).cgColor,
        tealPrimary.withAlphaComponent(0.05).cgColor
    ] as CFArray
    let glassGrad = CGGradient(colorsSpace: colorSpace, colors: glassColors, locations: [0, 1])!
    ctx.drawLinearGradient(glassGrad,
        start: CGPoint(x: lensCenter.x, y: lensCenter.y + lensRadius),
        end: CGPoint(x: lensCenter.x, y: lensCenter.y - lensRadius),
        options: [])
    ctx.restoreGState()

    // Lens ring — teal gradient stroke
    let ringWidth = s * 0.03
    ctx.setLineWidth(ringWidth)
    let tealGradColors = [tealLight.cgColor, tealPrimary.cgColor] as CFArray
    let tealGrad = CGGradient(colorsSpace: colorSpace, colors: tealGradColors, locations: [0, 1])!

    ctx.saveGState()
    let ringPath = CGMutablePath()
    ringPath.addEllipse(in: lensRect)
    let strokedRing = ringPath.copy(strokingWithWidth: ringWidth, lineCap: .round, lineJoin: .miter, miterLimit: 10)
    ctx.addPath(strokedRing)
    ctx.clip()
    ctx.drawLinearGradient(tealGrad,
        start: CGPoint(x: lensRect.minX, y: lensRect.maxY),
        end: CGPoint(x: lensRect.maxX, y: lensRect.minY),
        options: [])
    ctx.restoreGState()

    // Lens shine highlight
    ctx.saveGState()
    let shineCenter = CGPoint(x: lensCenter.x - lensRadius * 0.3, y: lensCenter.y + lensRadius * 0.3)
    let shineRadius = lensRadius * 0.35
    ctx.setFillColor(NSColor.white.withAlphaComponent(0.12).cgColor)
    ctx.fillEllipse(in: CGRect(
        x: shineCenter.x - shineRadius,
        y: shineCenter.y - shineRadius,
        width: shineRadius * 2,
        height: shineRadius * 2
    ))
    ctx.restoreGState()

    // Handle — angled down-right
    let handleAngle: CGFloat = -CGFloat.pi / 4 // 45 degrees down-right
    let handleStart = CGPoint(
        x: lensCenter.x + cos(handleAngle) * lensRadius,
        y: lensCenter.y + sin(handleAngle) * lensRadius
    )
    let handleEnd = CGPoint(
        x: handleStart.x + cos(handleAngle) * handleLength,
        y: handleStart.y + sin(handleAngle) * handleLength
    )

    ctx.setLineWidth(handleWidth)
    ctx.setLineCap(.round)

    // Handle gradient
    ctx.saveGState()
    let handlePath = CGMutablePath()
    handlePath.move(to: handleStart)
    handlePath.addLine(to: handleEnd)
    let strokedHandle = handlePath.copy(strokingWithWidth: handleWidth, lineCap: .round, lineJoin: .miter, miterLimit: 10)
    ctx.addPath(strokedHandle)
    ctx.clip()
    let handleColors = [tealPrimary.cgColor, tealPrimary.withAlphaComponent(0.7).cgColor] as CFArray
    let handleGrad = CGGradient(colorsSpace: colorSpace, colors: handleColors, locations: [0, 1])!
    ctx.drawLinearGradient(handleGrad, start: handleStart, end: handleEnd, options: [])
    ctx.restoreGState()

    // --- M+ Badge — pill shape bottom-right ---
    let badgeHeight = s * 0.18
    let badgeWidth = s * 0.28
    let badgePadding = s * 0.1
    let badgeRect = CGRect(
        x: s - badgeWidth - badgePadding,
        y: badgePadding,
        width: badgeWidth,
        height: badgeHeight
    )
    let badgePath = CGPath(roundedRect: badgeRect, cornerWidth: badgeHeight / 2, cornerHeight: badgeHeight / 2, transform: nil)
    ctx.addPath(badgePath)
    ctx.setFillColor(tealPrimary.cgColor)
    ctx.fillPath()

    // "M+" text in badge
    let fontSize = badgeHeight * 0.6
    let font = CTFontCreateWithName("Helvetica-Bold" as CFString, fontSize, nil)
    let attrs: [NSAttributedString.Key: Any] = [
        .font: font as Any,
        .foregroundColor: NSColor.white,
    ]
    let attrStr = NSAttributedString(string: "M+", attributes: attrs)
    let line = CTLineCreateWithAttributedString(attrStr)
    let textBounds = CTLineGetBoundsWithOptions(line, [])
    let textX = badgeRect.midX - textBounds.width / 2 - textBounds.origin.x
    let textY = badgeRect.midY - textBounds.height / 2 - textBounds.origin.y

    ctx.textPosition = CGPoint(x: textX, y: textY)
    CTLineDraw(line, ctx)

    image.unlockFocus()
    return image
}

// MARK: - PNG Export

func savePNGAtSize(_ image: NSImage, pixelSize: Int, to url: URL) {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pixelSize,
        pixelsHigh: pixelSize,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    )!
    rep.size = NSSize(width: pixelSize, height: pixelSize)

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    image.draw(in: NSRect(x: 0, y: 0, width: pixelSize, height: pixelSize),
               from: .zero, operation: .copy, fraction: 1.0)
    NSGraphicsContext.restoreGraphicsState()

    guard let pngData = rep.representation(using: .png, properties: [:]) else {
        print("ERROR: Failed to create PNG for \(url.lastPathComponent)")
        return
    }
    do {
        try pngData.write(to: url)
        print("  Created: \(url.lastPathComponent)")
    } catch {
        print("ERROR: \(error.localizedDescription)")
    }
}

// MARK: - Main

let projectDir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let resourcesDir = projectDir.appendingPathComponent("Resources")

try FileManager.default.createDirectory(at: resourcesDir, withIntermediateDirectories: true)

// --- Generate App Icon ---
print("Generating App Icon...")

let iconsetDir = resourcesDir.appendingPathComponent("AppIcon.iconset")
try? FileManager.default.removeItem(at: iconsetDir)
try FileManager.default.createDirectory(at: iconsetDir, withIntermediateDirectories: true)

let iconSizes: [(name: String, pixels: Int)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024),
]

let masterIcon = generateAppIcon(size: 1024)

for entry in iconSizes {
    let url = iconsetDir.appendingPathComponent(entry.name)
    savePNGAtSize(masterIcon, pixelSize: entry.pixels, to: url)
}

// Also save 1024px PNG for web/marketing
savePNGAtSize(masterIcon, pixelSize: 1024, to: resourcesDir.appendingPathComponent("AppIcon.png"))

// Convert to .icns
print("Converting to .icns...")
let icnsPath = resourcesDir.appendingPathComponent("AppIcon.icns").path
let task = Process()
task.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
task.arguments = ["-c", "icns", iconsetDir.path, "-o", icnsPath]
try task.run()
task.waitUntilExit()

if task.terminationStatus == 0 {
    print("  Created: AppIcon.icns")
    try? FileManager.default.removeItem(at: iconsetDir)
} else {
    print("ERROR: iconutil failed with status \(task.terminationStatus)")
}

print("\nDone! Generated assets in Resources/")
