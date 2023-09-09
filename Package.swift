// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Throttler",
    platforms: [
        .macOS(.v13),
        .iOS(.v16),
        .watchOS(.v9),
        .tvOS(.v16)
    ],
    products: [
        .library(
            name: "Throttler",
            targets: ["Throttler"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "Throttler",
            dependencies: []),
        .testTarget(
            name: "ThrottlerTests",
            dependencies: ["Throttler"]),
    ]
)
