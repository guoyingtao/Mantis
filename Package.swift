// swift-tools-version:6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Mantis",
    defaultLocalization: "en",
    platforms: [.iOS(.v17), .macCatalyst(.v17)],
    products: [
        .library(
            name: "Mantis",
            targets: ["Mantis"])
    ],
    targets: [
        .target(
            name: "Mantis",
            resources: [.process("Resources"), .copy("PrivacyInfo.xcprivacy")],
            swiftSettings: [.enableUpcomingFeature("IsolatedDefaultValues")]
        ),
        .testTarget(
            name: "MantisTests",
            dependencies: ["Mantis"],
            path: "Tests/MantisTests"
        )
    ],
    // Tools 6.0 defaults to the Swift 6 language mode; Mantis still builds in Swift 5 mode.
    swiftLanguageModes: [.v5]
)
