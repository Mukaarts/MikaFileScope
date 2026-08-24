// swift-tools-version: 6.0
import PackageDescription
import Foundation

// Zwei Bauvarianten aus einer Quelle:
//
//   swift build                      → Direktvertrieb, mit Sparkle
//   APPSTORE=1 swift build           → Store-Variante, ohne Sparkle
//
// Der Store lässt keinen eigenen Update-Mechanismus zu, und ein bloßes `#if` im Code
// genügt nicht: Das Programm wäre weiterhin gegen das Framework gelinkt. Deshalb
// entfällt die Abhängigkeit in dieser Variante vollständig.
let isAppStore = ProcessInfo.processInfo.environment["APPSTORE"] == "1"

let package = Package(
    name: "MikaFileScope",
    platforms: [.macOS(.v14)],
    dependencies: isAppStore ? [] : [
        .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.6.0"),
    ],
    targets: [
        .executableTarget(
            name: "MikaFileScope",
            dependencies: isAppStore ? [] : [
                .product(name: "Sparkle", package: "Sparkle"),
            ],
            path: "Sources",
            swiftSettings: isAppStore ? [.define("APPSTORE")] : []
        ),
        .testTarget(
            name: "UpdateChannelTests",
            path: "Tests/UpdateChannelTests"
        ),
        .testTarget(
            name: "CoreLogicTests",
            dependencies: ["MikaFileScope"],
            path: "Tests/CoreLogicTests"
        )
    ]
)
