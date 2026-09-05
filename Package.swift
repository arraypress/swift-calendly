// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Calendly",
    platforms: [
        .macOS(.v14), .iOS(.v16), .tvOS(.v16), .watchOS(.v9), .visionOS(.v1),
    ],
    products: [
        .library(name: "Calendly", targets: ["Calendly"]),
    ],
    targets: [
        .target(name: "Calendly"),
        .testTarget(name: "CalendlyTests", dependencies: ["Calendly"]),
    ]
)
