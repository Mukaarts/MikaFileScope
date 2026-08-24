#!/usr/bin/env swift
// GenerateOGImage.swift — Generates the 1200x630 social preview for the website
// Run: swift scripts/GenerateOGImage.swift

import AppKit

let width = 1200
let height = 630

let projectDir = FileManager.default.currentDirectoryPath
let iconPath = "\(projectDir)/Resources/AppIcon.png"
// JPEG, not PNG: the artwork is a smooth gradient with no transparency, and a
// lossless export lands around 3.5 MB — far past what link-preview crawlers want.
let outputPath = "\(projectDir)/website/assets/og-image.jpg"

// Mika+ palette (mirrors Sources/MikaPlusColors.swift)
let darkBgDeep = NSColor(srgbRed: 0x0F/255.0, green: 0x0F/255.0, blue: 0x1A/255.0, alpha: 1.0)
let darkBg     = NSColor(srgbRed: 0x1A/255.0, green: 0x1A/255.0, blue: 0x2E/255.0, alpha: 1.0)
let teal       = NSColor(srgbRed: 0x1D/255.0, green: 0x9E/255.0, blue: 0x75/255.0, alpha: 1.0)
let tealLight  = NSColor(srgbRed: 0x5D/255.0, green: 0xCA/255.0, blue: 0xA5/255.0, alpha: 1.0)
let textPrim   = NSColor(srgbRed: 0xE8/255.0, green: 0xF3/255.0, blue: 0xEE/255.0, alpha: 1.0)
let textMuted  = NSColor(srgbRed: 0xA3/255.0, green: 0xB2/255.0, blue: 0xAE/255.0, alpha: 1.0)

// Draw into a bitmap with explicit pixel dimensions rather than NSImage.lockFocus():
// on a Retina display the latter doubles the resolution, and the 1200x630 declared in
// index.html would ship as a 2400x1260 file.
guard let bitmap = NSBitmapImageRep(
    bitmapDataPlanes: nil, pixelsWide: width, pixelsHigh: height,
    bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
    colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0) else {
    print("Failed to create bitmap")
    exit(1)
}
bitmap.size = NSSize(width: width, height: height)
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)

// Background gradient
NSGradient(starting: darkBgDeep, ending: darkBg)!
    .draw(in: NSRect(x: 0, y: 0, width: width, height: height), angle: 65)

// Teal glow behind the icon. The gradient rect extends well past every edge of
// the canvas so its own boundary never shows up as a seam in the artwork.
let glow = NSGradient(colors: [teal.withAlphaComponent(0.42), teal.withAlphaComponent(0.0)])!
let glowSize: CGFloat = 2200
let iconCenter = NSPoint(x: 236, y: 315)
glow.draw(in: NSRect(x: iconCenter.x - glowSize / 2,
                     y: iconCenter.y - glowSize / 2,
                     width: glowSize, height: glowSize),
          relativeCenterPosition: .zero)

// Dot grid, echoing the app icon backdrop
let dotColor = tealLight.withAlphaComponent(0.09)
dotColor.setFill()
for x in stride(from: 20, to: width, by: 26) {
    for y in stride(from: 20, to: height, by: 26) {
        NSBezierPath(ovalIn: NSRect(x: x, y: y, width: 2, height: 2)).fill()
    }
}

// App icon
if let icon = NSImage(contentsOfFile: iconPath) {
    icon.draw(in: NSRect(x: 96, y: 175, width: 280, height: 280),
              from: .zero, operation: .sourceOver, fraction: 1.0)
}

// Text block
let textX: CGFloat = 440

func draw(_ text: String, x: CGFloat, y: CGFloat, size: CGFloat,
          weight: NSFont.Weight, color: NSColor, tracking: CGFloat = 0) {
    let style = NSMutableParagraphStyle()
    style.lineBreakMode = .byWordWrapping
    let attrs: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: size, weight: weight),
        .foregroundColor: color,
        .kern: tracking,
        .paragraphStyle: style,
    ]
    (text as NSString).draw(at: NSPoint(x: x, y: y), withAttributes: attrs)
}

// Eyebrow
draw("NATIVE macOS UTILITY", x: textX, y: 430, size: 19, weight: .semibold,
     color: tealLight, tracking: 2.4)

// Wordmark — "Mika" + teal "+" + "FileScope"
let titleSize: CGFloat = 62
let titleAttrs: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: titleSize, weight: .bold),
    .foregroundColor: textPrim,
    .kern: -1.6,
]
let plusAttrs: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: titleSize, weight: .bold),
    .foregroundColor: tealLight,
    .kern: -1.6,
]
let wordmark = NSMutableAttributedString(string: "Mika", attributes: titleAttrs)
wordmark.append(NSAttributedString(string: "+", attributes: plusAttrs))
wordmark.append(NSAttributedString(string: "FileScope", attributes: titleAttrs))
wordmark.draw(at: NSPoint(x: textX, y: 340))

// Tagline
draw("See what's actually filling your disk.", x: textX, y: 280,
     size: 30, weight: .medium, color: textPrim, tracking: -0.5)

// Supporting line
draw("Scan any folder · Group by file type · Charts,", x: textX, y: 224,
     size: 23, weight: .regular, color: textMuted)
draw("age timeline and SHA-256 duplicate finder", x: textX, y: 190,
     size: 23, weight: .regular, color: textMuted)

// Footer meta with a teal rule
teal.setFill()
NSBezierPath(rect: NSRect(x: textX, y: 148, width: 54, height: 3)).fill()
draw("macOS 14+ · Free · Open source", x: textX, y: 104,
     size: 20, weight: .medium, color: textMuted)

NSGraphicsContext.restoreGraphicsState()

guard let jpeg = bitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.92]) else {
    print("Failed to render OG image")
    exit(1)
}

do {
    try jpeg.write(to: URL(fileURLWithPath: outputPath))
    print("Wrote \(outputPath) (\(width)x\(height))")
} catch {
    print("Failed to write: \(error)")
    exit(1)
}
