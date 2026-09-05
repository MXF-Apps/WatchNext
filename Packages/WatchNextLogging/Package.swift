// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "WatchNextLogging",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [
        .library(name: "WatchNextLogging", targets: ["WatchNextLogging"])
    ],
    targets: [
        .target(name: "WatchNextLogging"),
        .testTarget(
            name: "WatchNextLoggingTests",
            dependencies: ["WatchNextLogging"]
        )
    ],
    swiftLanguageModes: [.v6]
)
