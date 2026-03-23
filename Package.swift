// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MikaFileScope",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "MikaFileScope",
            path: "Sources"
        )
    ]
)
