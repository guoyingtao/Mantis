// swift-tools-version:6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Mantis",
    defaultLocalization: "en",
    // macOS is for MantisCore only; the Mantis UI product needs UIKit.
    platforms: [.iOS(.v17), .macCatalyst(.v17), .macOS(.v14)],
    products: [
        .library(
            name: "Mantis",
            targets: ["Mantis"]),
        .library(
            name: "MantisCore",
            targets: ["MantisCore"])
    ],
    targets: [
        .target(
            name: "MantisCore"
        ),
        .target(
            name: "Mantis",
            dependencies: ["MantisCore"],
            resources: [.process("Resources"), .copy("PrivacyInfo.xcprivacy")],
            swiftSettings: [.enableUpcomingFeature("IsolatedDefaultValues")]
        ),
        .testTarget(
            name: "MantisTests",
            dependencies: ["Mantis"],
            path: "Tests/MantisTests"
        ),
        .testTarget(
            name: "MantisCoreTests",
            dependencies: ["MantisCore"],
            path: "Tests/MantisCoreTests"
        )
    ],
    // Tools 6.0 defaults to the Swift 6 language mode; Mantis still builds in Swift 5 mode.
    swiftLanguageModes: [.v5]
)
