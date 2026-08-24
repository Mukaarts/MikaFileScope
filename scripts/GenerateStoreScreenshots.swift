#!/usr/bin/env swift
// GenerateStoreScreenshots.swift — baut aus den rohen Fensteraufnahmen die
// gestalteten 2880×1800-Bilder für den Mac App Store.
//
// Aufruf: swift scripts/GenerateStoreScreenshots.swift <ordner-mit-rohaufnahmen>
//
// Erwartet dort 1-liste.png … 5-videos.png.
//
// Aufbau je Bild, von oben nach unten:
//   1. sehr große fette Überschrift — die eine Aussage, in zwei Sekunden lesbar
//   2. das Fenster, groß und unten angeschnitten, damit es nicht wie ein
//      abgelegtes Foto wirkt, sondern wie ein Ausschnitt aus etwas Größerem
//   3. eine Karte davor mit der Kennzahl, die im Fenster steht — sie fängt den
//      Blick, bevor jemand die Tabelle liest
//
// Heller Grund mit einem Hauch der Markenfarbe: Die App zeigt sich im dunklen
// Erscheinungsbild, und der Kontrast dazu trägt das Fenster.

import AppKit

let canvas = NSSize(width: 2880, height: 1800)

// Mika+ Palette — Spiegel von Sources/MikaPlusColors.swift
let teal      = NSColor(srgbRed: 0x1D/255.0, green: 0x9E/255.0, blue: 0x75/255.0, alpha: 1)
let tealTief  = NSColor(srgbRed: 0x11/255.0, green: 0x6B/255.0, blue: 0x4E/255.0, alpha: 1)
let grundOben = NSColor(srgbRed: 0xFA/255.0, green: 0xFD/255.0, blue: 0xFB/255.0, alpha: 1)
let grundUnten = NSColor(srgbRed: 0xDF/255.0, green: 0xF0/255.0, blue: 0xE8/255.0, alpha: 1)
let tinte     = NSColor(srgbRed: 0x0B/255.0, green: 0x14/255.0, blue: 0x11/255.0, alpha: 1)
let tinteMatt = NSColor(srgbRed: 0x4A/255.0, green: 0x5B/255.0, blue: 0x55/255.0, alpha: 1)

struct Folie {
    let datei: String
    let titel: String       // die Aussage, groß und fett
    let zahl: String        // die Kennzahl aus genau diesem Screenshot
    let label: String       // was die Zahl bedeutet
    let satz: String        // ein Satz Erklärung neben der Zahl
}

// Reihenfolge im Store: erst die Frage, die das Produkt beantwortet, dann was es
// zeigt, zuletzt das Argument zum Aufräumen.
let folien = [
    Folie(datei: "1-liste",
          titel: "Wo ist der Platz\ngeblieben?",
          zahl: "4,17 GB",
          label: "in 18 Dateien",
          satz: "Jede Dateiendung mit Anzahl, Größe und Anteil am Ganzen — sortierbar nach jeder Spalte."),
    Folie(datei: "2-diagramme",
          titel: "Auf einen Blick",
          zahl: "59,5 %",
          label: "entfallen auf .MOV",
          satz: "Ring und Balken zeigen die acht größten Typen, alles Weitere fasst „Other“ zusammen."),
    Folie(datei: "3-zeitachse",
          titel: "Was hier nur herumliegt",
          zahl: "6",
          label: "Altersstufen",
          satz: "Von heute bis älter als ein Jahr — nach Anzahl und nach belegtem Platz getrennt."),
    Folie(datei: "4-duplikate",
          titel: "Doppelt gespeichert",
          zahl: "8,6 MB",
          label: "wiedergewinnbar",
          satz: "SHA-256 findet, was wirklich gleich ist. Gelöscht wird nichts — das bleibt Ihre Sache."),
    Folie(datei: "5-videos",
          titel: "Nur das, was zählt",
          zahl: "3,4 GB",
          label: "in 3 Videodateien",
          satz: "Sieben Kategorien engen die Ansicht ein — Tabelle, Diagramme und Export folgen mit."),
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

/// Zeichnet Text in eine Box fester Breite und meldet die belegte Höhe zurück.
/// `obenBei` ist die Oberkante — bei AppKit-Koordinaten muss von dort nach unten
/// gerechnet werden, sonst hängt mehrzeiliger Text am falschen Ende fest.
@discardableResult
func zeichne(_ text: String, schrift: NSFont, farbe: NSColor,
             breite: CGFloat, x: CGFloat, obenBei y: CGFloat,
             zeilen: CGFloat = 1.0, ausrichtung: NSTextAlignment = .center,
             kerning: CGFloat = 0) -> CGFloat {
    let stil = NSMutableParagraphStyle()
    stil.alignment = ausrichtung
    stil.lineHeightMultiple = zeilen
    let s = NSAttributedString(string: text, attributes: [
        .font: schrift, .foregroundColor: farbe,
        .paragraphStyle: stil, .kern: kerning,
    ])
    let mass = s.boundingRect(with: NSSize(width: breite, height: .greatestFiniteMagnitude),
                              options: [.usesLineFragmentOrigin])
    s.draw(with: NSRect(x: x, y: y - mass.height, width: breite, height: mass.height),
           options: [.usesLineFragmentOrigin])
    return mass.height
}

for folie in folien {
    let pfad = "\(quelle)/\(folie.datei).png"
    guard let aufnahme = NSImage(contentsOfFile: pfad) else {
        print("  ✗ fehlt: \(pfad)")
        continue
    }

    // Feste Pixelmaße statt NSImage.lockFocus(): Letzteres verdoppelt auf einem
    // Retina-Display die Auflösung, und der Store weist 5760×3600 zurück.
    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: Int(canvas.width), pixelsHigh: Int(canvas.height),
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)
    else { continue }
    rep.size = canvas

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

    let alles = NSRect(origin: .zero, size: canvas)

    // --- Grund ------------------------------------------------------------
    NSGradient(colors: [grundOben, grundUnten])?.draw(in: alles, angle: -90)

    // Ein weicher Schein in Markenfarbe hinter der Überschrift, damit die obere
    // Bildhälfte nicht leer wirkt.
    NSGraphicsContext.current?.saveGraphicsState()
    let schein = NSGradient(colors: [teal.withAlphaComponent(0.16), teal.withAlphaComponent(0)])
    schein?.draw(in: NSRect(x: canvas.width/2 - 1400, y: canvas.height - 1200,
                            width: 2800, height: 1400), relativeCenterPosition: .zero)
    NSGraphicsContext.current?.restoreGraphicsState()

    // Feines Punktraster, sehr blass — gibt der Fläche Struktur ohne Ablenkung.
    teal.withAlphaComponent(0.07).setFill()
    var py: CGFloat = 40
    while py < canvas.height {
        var px: CGFloat = 40
        while px < canvas.width {
            NSBezierPath(ovalIn: NSRect(x: px, y: py, width: 5, height: 5)).fill()
            px += 72
        }
        py += 72
    }

    // --- Überschrift ------------------------------------------------------
    let titelOben = canvas.height - 130
    let titelHoehe = zeichne(folie.titel,
            schrift: .systemFont(ofSize: 148, weight: .black), farbe: tinte,
            breite: 2400, x: canvas.width/2 - 1200, obenBei: titelOben,
            zeilen: 0.92, kerning: -3)

    // --- Fenster ----------------------------------------------------------
    // Unten angeschnitten: Das Bild endet nicht mit dem Fenster, es geht weiter.
    let quellMass = aufnahme.size
    let fensterBreite: CGFloat = 2360
    let fensterHoehe = fensterBreite * quellMass.height / quellMass.width
    // Direkt unter der Überschrift ansetzen: Eine dreizeilige Zeile schiebt das
    // Fenster nach unten, eine einzeilige zieht es hoch — der Abstand bleibt gleich.
    let fensterOben = titelOben - titelHoehe - 110
    let fenster = NSRect(x: (canvas.width - fensterBreite)/2,
                         y: fensterOben - fensterHoehe,
                         width: fensterBreite, height: fensterHoehe)
    let rahmen = NSBezierPath(roundedRect: fenster, xRadius: 26, yRadius: 26)

    NSGraphicsContext.current?.saveGraphicsState()
    let fensterSchatten = NSShadow()
    fensterSchatten.shadowColor = tealTief.withAlphaComponent(0.30)
    fensterSchatten.shadowBlurRadius = 70
    fensterSchatten.shadowOffset = NSSize(width: 0, height: -24)
    fensterSchatten.set()
    NSColor.black.setFill()
    rahmen.fill()
    NSGraphicsContext.current?.restoreGraphicsState()

    NSGraphicsContext.current?.saveGraphicsState()
    rahmen.addClip()
    aufnahme.draw(in: fenster, from: .zero, operation: .sourceOver, fraction: 1)
    NSGraphicsContext.current?.restoreGraphicsState()

    // --- Kennzahlkarte ----------------------------------------------------
    // Liegt vor dem Fenster und überlappt es. Sie trägt die Zahl, die im
    // Screenshot steht — nichts Erfundenes.
    let karte = NSRect(x: 300, y: 78, width: canvas.width - 600, height: 300)
    let karteRahmen = NSBezierPath(roundedRect: karte, xRadius: 44, yRadius: 44)

    NSGraphicsContext.current?.saveGraphicsState()
    let karteSchatten = NSShadow()
    karteSchatten.shadowColor = tealTief.withAlphaComponent(0.26)
    karteSchatten.shadowBlurRadius = 56
    karteSchatten.shadowOffset = NSSize(width: 0, height: -14)
    karteSchatten.set()
    NSColor.white.setFill()
    karteRahmen.fill()
    NSGraphicsContext.current?.restoreGraphicsState()

    // Zahl links, Erklärung rechts, dazwischen ein Trennstrich.
    zeichne(folie.zahl,
            schrift: .systemFont(ofSize: 104, weight: .bold), farbe: tealTief,
            breite: 620, x: karte.minX + 80, obenBei: karte.maxY - 52,
            ausrichtung: .left, kerning: -2)
    zeichne(folie.label,
            schrift: .systemFont(ofSize: 42, weight: .medium), farbe: tinteMatt,
            breite: 620, x: karte.minX + 80, obenBei: karte.maxY - 168,
            ausrichtung: .left)

    tinteMatt.withAlphaComponent(0.22).setFill()
    NSBezierPath(rect: NSRect(x: karte.minX + 780, y: karte.minY + 58,
                              width: 3, height: karte.height - 116)).fill()

    let satzBreite = karte.maxX - (karte.minX + 880) - 80
    let satzHoehe = NSAttributedString(string: folie.satz, attributes: [
        .font: NSFont.systemFont(ofSize: 50, weight: .regular),
    ]).boundingRect(with: NSSize(width: satzBreite, height: .greatestFiniteMagnitude),
                    options: [.usesLineFragmentOrigin]).height
    zeichne(folie.satz,
            schrift: .systemFont(ofSize: 50, weight: .regular), farbe: tinteMatt,
            breite: satzBreite, x: karte.minX + 880,
            obenBei: karte.midY + satzHoehe/2 + 14,
            zeilen: 1.18, ausrichtung: .left)

    NSGraphicsContext.restoreGraphicsState()

    guard let jpeg = rep.representation(using: .jpeg, properties: [.compressionFactor: 0.92]) else {
        print("  ✗ Kodierung fehlgeschlagen: \(folie.datei)")
        continue
    }
    let zielPfad = "\(ziel)/\(folie.datei).jpg"
    try? jpeg.write(to: URL(fileURLWithPath: zielPfad))
    print("  ✓ \(folie.datei).jpg — \(jpeg.count / 1024) KB")
}
