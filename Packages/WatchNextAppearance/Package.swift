// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "WatchNextAppearance",
    defaultLocalization: "en",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [
        .library(name: "WatchNextAppearance", targets: ["WatchNextAppearance"])
    ],
    targets: [
        .target(name: "WatchNextAppearance"),
        .testTarget(
            name: "WatchNextAppearanceTests",
            dependencies: ["WatchNextAppearance"]
        )
    ],
    swiftLanguageModes: [.v6]
)
