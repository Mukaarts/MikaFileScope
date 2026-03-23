#!/usr/bin/env swift
// GenerateDMGBackground.swift — Generates DMG installer background image
// Run: swift scripts/GenerateDMGBackground.swift

import AppKit

let width = 1200  // 600pt @2x
let height = 800  // 400pt @2x

let image = NSImage(size: NSSize(width: width, height: height))
image.lockFocus()

let context = NSGraphicsContext.current!.cgContext

// Background gradient: dark navy
let darkBgDeep = NSColor(srgbRed: 0x0F/255.0, green: 0x0F/255.0, blue: 0x1A/255.0, alpha: 1.0)
let darkBg = NSColor(srgbRed: 0x1A/255.0, green: 0x1A/255.0, blue: 0x2E/255.0, alpha: 1.0)

let gradient = NSGradient(starting: darkBgDeep, ending: darkBg)!
gradient.draw(in: NSRect(x: 0, y: 0, width: width, height: height), angle: 90)

// Subtle grid lines
let gridColor = NSColor(srgbRed: 0x1D/255.0, green: 0x9E/255.0, blue: 0x75/255.0, alpha: 0.08)
gridColor.setStroke()
let gridPath = NSBezierPath()
gridPath.lineWidth = 1.0
for x in stride(from: 0, through: width, by: 40) {
    gridPath.move(to: NSPoint(x: x, y: 0))
    gridPath.line(to: NSPoint(x: x, y: height))
}
for y in stride(from: 0, through: height, by: 40) {
    gridPath.move(to: NSPoint(x: 0, y: y))
    gridPath.line(to: NSPoint(x: width, y: y))
}
gridPath.stroke()

// Arrow from app to Applications
let arrowColor = NSColor(srgbRed: 0x5D/255.0, green: 0xCA/255.0, blue: 0xA5/255.0, alpha: 0.4)
arrowColor.setStroke()
let arrowPath = NSBezierPath()
arrowPath.lineWidth = 3.0
let arrowY = height / 2 + 20
arrowPath.move(to: NSPoint(x: 400, y: arrowY))
arrowPath.line(to: NSPoint(x: 780, y: arrowY))
arrowPath.move(to: NSPoint(x: 760, y: arrowY + 20))
arrowPath.line(to: NSPoint(x: 780, y: arrowY))
arrowPath.line(to: NSPoint(x: 760, y: arrowY - 20))
arrowPath.stroke()

// "Drag to install" text
let textColor = NSColor(srgbRed: 0x9F/255.0, green: 0xE1/255.0, blue: 0xCB/255.0, alpha: 0.6)
let attrs: [NSAttributedString.Key: Any] = [
    .foregroundColor: textColor,
    .font: NSFont.systemFont(ofSize: 24, weight: .medium),
]
let text = "Drag to Applications to install"
let textSize = text.size(withAttributes: attrs)
let textX = (CGFloat(width) - textSize.width) / 2
text.draw(at: NSPoint(x: textX, y: 100), withAttributes: attrs)

// App name at top
let titleColor = NSColor(srgbRed: 0xE1/255.0, green: 0xF5/255.0, blue: 0xEE/255.0, alpha: 0.9)
let titleAttrs: [NSAttributedString.Key: Any] = [
    .foregroundColor: titleColor,
    .font: NSFont.systemFont(ofSize: 32, weight: .bold),
]
let title = "Mika+FileScope"
let titleSize = title.size(withAttributes: titleAttrs)
let titleX = (CGFloat(width) - titleSize.width) / 2
title.draw(at: NSPoint(x: titleX, y: CGFloat(height) - 80), withAttributes: titleAttrs)

image.unlockFocus()

// Save
let projectDir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let installerDir = projectDir.appendingPathComponent("installer")
try! FileManager.default.createDirectory(at: installerDir, withIntermediateDirectories: true)

let tiffData = image.tiffRepresentation!
let bitmapRep = NSBitmapImageRep(data: tiffData)!
let pngData = bitmapRep.representation(using: .png, properties: [:])!

// Save @2x version
try! pngData.write(to: installerDir.appendingPathComponent("dmg-background@2x.png"))

// Save @1x version (600x400)
let smallImage = NSImage(size: NSSize(width: 600, height: 400))
smallImage.lockFocus()
image.draw(in: NSRect(x: 0, y: 0, width: 600, height: 400))
smallImage.unlockFocus()
let smallTiff = smallImage.tiffRepresentation!
let smallRep = NSBitmapImageRep(data: smallTiff)!
let smallPng = smallRep.representation(using: .png, properties: [:])!
try! smallPng.write(to: installerDir.appendingPathComponent("dmg-background.png"))

print("DMG backgrounds generated in installer/")
