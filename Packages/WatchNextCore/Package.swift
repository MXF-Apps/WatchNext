// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "WatchNextCore",
    defaultLocalization: "en",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [
        .library(name: "WatchNextCore", targets: ["WatchNextCore"])
    ],
    dependencies: [
        .package(path: "../WatchNextLogging")
    ],
    targets: [
        .target(
            name: "WatchNextCore",
            dependencies: [
                .product(name: "WatchNextLogging", package: "WatchNextLogging")
            ],
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "WatchNextTests",
            dependencies: ["WatchNextCore"],
            resources: [.process("Fixtures")]
        )
    ],
    swiftLanguageModes: [.v6]
)
