#!/usr/bin/env swift
// GenerateStoreScreenshots.swift — baut aus den rohen Fensteraufnahmen die
// gestalteten 2880×1800-Bilder für den Mac App Store.
//
// Aufruf: swift scripts/GenerateStoreScreenshots.swift <ordner-mit-rohaufnahmen>
//
// Erwartet dort 1-liste.png … 5-videos.png, wie sie
// scripts/capture-store-screenshots.sh erzeugt.
//
// Warum gestaltet und nicht nackt: Ein Store-Eintrag hat wenige Sekunden. Eine
// Fensteraufnahme allein erklärt nichts — die Überschrift sagt, was man sieht,
// bevor jemand die Zahlen liest.

import AppKit

let canvas = NSSize(width: 2880, height: 1800)

// Mika+ Palette — Spiegel von Sources/MikaPlusColors.swift
let darkBgDeep = NSColor(srgbRed: 0x0F/255.0, green: 0x0F/255.0, blue: 0x1A/255.0, alpha: 1)
let darkBg     = NSColor(srgbRed: 0x1A/255.0, green: 0x1A/255.0, blue: 0x2E/255.0, alpha: 1)
let teal       = NSColor(srgbRed: 0x1D/255.0, green: 0x9E/255.0, blue: 0x75/255.0, alpha: 1)
let tealLight  = NSColor(srgbRed: 0x5D/255.0, green: 0xCA/255.0, blue: 0xA5/255.0, alpha: 1)
let textPrim   = NSColor(srgbRed: 0xE8/255.0, green: 0xF3/255.0, blue: 0xEE/255.0, alpha: 1)
let textMuted  = NSColor(srgbRed: 0xA3/255.0, green: 0xB2/255.0, blue: 0xAE/255.0, alpha: 1)

struct Folie {
    let datei: String
    let titel: String
    let unterzeile: String
}

// Die Reihenfolge ist die im Store: erst die Frage, die das Produkt beantwortet,
// dann die Bilder, dann das Kaufargument.
let folien = [
    Folie(datei: "1-liste",
          titel: "Wo ist der Platz geblieben?",
          unterzeile: "Jede Dateiendung mit Anzahl, Größe und Anteil am Ganzen"),
    Folie(datei: "2-diagramme",
          titel: "Auf einen Blick",
          unterzeile: "Ringdiagramm und Balken — die acht größten Typen, der Rest gebündelt"),
    Folie(datei: "3-zeitachse",
          titel: "Was liegt hier nur herum?",
          unterzeile: "Verteilung nach Alter — getrennt nach Anzahl und nach Volumen"),
    Folie(datei: "4-duplikate",
          titel: "Doppelt gespeichert",
          unterzeile: "SHA-256 findet, was wirklich gleich ist. Gelöscht wird nichts."),
    Folie(datei: "5-videos",
          titel: "Nur das, was zählt",
          unterzeile: "Sieben Kategorien — Tabelle, Diagramme und Export folgen der Auswahl"),
]

let args = CommandLine.arguments
guard args.count > 1 else {
    print("Aufruf: swift scripts/GenerateStoreScreenshots.swift <ordner-mit-rohaufnahmen>")
    exit(1)
}
let quelle = args[1]
let projekt = FileManager.default.currentDirectoryPath
let ziel = "\(projekt)/store/screenshots"
try? FileManager.default.createDirectory(atPath: ziel, withIntermediateDirectories: true)

func schrift(_ groesse: CGFloat, _ gewicht: NSFont.Weight) -> NSFont {
    NSFont.systemFont(ofSize: groesse, weight: gewicht)
}

for folie in folien {
    let pfad = "\(quelle)/\(folie.datei).png"
    guard let aufnahme = NSImage(contentsOfFile: pfad) else {
        print("  ! fehlt: \(pfad)")
        continue
    }

    // In eine Bitmap mit festen Pixelmaßen zeichnen, nicht über NSImage.lockFocus():
    // Auf einem Retina-Bildschirm verdoppelt lockFocus die Auflösung, und aus 2880×1800
    // werden 5760×3600. Der Store lehnt solche Bilder ab.
    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: Int(canvas.width), pixelsHigh: Int(canvas.height),
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)
    else { continue }
    rep.size = canvas

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

    // Hintergrund: derselbe Verlauf wie auf der Website und im OG-Bild
    NSGradient(starting: darkBgDeep, ending: darkBg)!
        .draw(in: NSRect(origin: .zero, size: canvas), angle: 65)

    // Teal-Schein hinter der Überschrift. Der Verlauf reicht weit über den Rand
    // hinaus, damit seine eigene Kante nie als Naht sichtbar wird.
    let schein = NSGradient(colors: [teal.withAlphaComponent(0.30), teal.withAlphaComponent(0)])!
    let scheinGroesse: CGFloat = 3400
    schein.draw(in: NSRect(x: canvas.width/2 - scheinGroesse/2,
                           y: canvas.height - 300 - scheinGroesse/2,
                           width: scheinGroesse, height: scheinGroesse),
                relativeCenterPosition: .zero)

    // Punktraster, wie im App-Symbol
    tealLight.withAlphaComponent(0.07).setFill()
    for x in stride(from: 30.0, to: canvas.width, by: 44) {
        for y in stride(from: 30.0, to: canvas.height, by: 44) {
            NSBezierPath(ovalIn: NSRect(x: x, y: y, width: 3.5, height: 3.5)).fill()
        }
    }

    // Überschrift
    let titelAttr: [NSAttributedString.Key: Any] = [
        .font: schrift(104, .bold),
        .foregroundColor: textPrim,
    ]
    let titelGroesse = folie.titel.size(withAttributes: titelAttr)
    folie.titel.draw(at: NSPoint(x: (canvas.width - titelGroesse.width)/2, y: canvas.height - 160),
                     withAttributes: titelAttr)

    // Unterzeile
    let unterAttr: [NSAttributedString.Key: Any] = [
        .font: schrift(46, .regular),
        .foregroundColor: textMuted,
    ]
    let unterGroesse = folie.unterzeile.size(withAttributes: unterAttr)
    folie.unterzeile.draw(at: NSPoint(x: (canvas.width - unterGroesse.width)/2, y: canvas.height - 240),
                          withAttributes: unterAttr)

    // Die Fensteraufnahme: proportional einpassen, zentriert, unten bündig
    // Die Breite folgt aus der Höhe, die nach Überschrift und Unterzeile übrig
    // bleibt: rund 300 px oben, 70 px Luft unten. Vorher war das Fenster so hoch,
    // dass es die Unterzeile verdeckte.
    let maxHoehe: CGFloat = 1420
    let maxBreite: CGFloat = min(2400, aufnahme.size.width * (maxHoehe / aufnahme.size.height))
    let skala = maxBreite / aufnahme.size.width
    let bildGroesse = NSSize(width: maxBreite, height: aufnahme.size.height * skala)
    let bildRahmen = NSRect(x: (canvas.width - bildGroesse.width)/2,
                            y: 70,
                            width: bildGroesse.width, height: bildGroesse.height)

    // Schatten, damit das Fenster auf dem Verlauf steht statt darin zu schwimmen
    NSGraphicsContext.saveGraphicsState()
    let schatten = NSShadow()
    schatten.shadowColor = NSColor.black.withAlphaComponent(0.55)
    schatten.shadowBlurRadius = 60
    schatten.shadowOffset = NSSize(width: 0, height: -18)
    schatten.set()
    let ecken = NSBezierPath(roundedRect: bildRahmen, xRadius: 22, yRadius: 22)
    darkBgDeep.setFill()
    ecken.fill()
    NSGraphicsContext.restoreGraphicsState()

    // Auf die abgerundeten Ecken beschneiden
    NSGraphicsContext.saveGraphicsState()
    ecken.addClip()
    aufnahme.draw(in: bildRahmen, from: .zero, operation: .sourceOver, fraction: 1)
    NSGraphicsContext.restoreGraphicsState()

    NSGraphicsContext.restoreGraphicsState()

    // Als JPEG sichern: der Store nimmt keinen Alpha-Kanal, und JPEG hat keinen.
    guard let daten = rep.representation(using: .jpeg, properties: [.compressionFactor: 0.92])
    else {
        print("  ! konnte \(folie.datei) nicht sichern")
        continue
    }
    let ausgabe = "\(ziel)/\(folie.datei).jpg"
    try? daten.write(to: URL(fileURLWithPath: ausgabe))
    print("  ✓ \(folie.datei).jpg — \(folie.titel)")
}

print("\nFertig: \(ziel)")
