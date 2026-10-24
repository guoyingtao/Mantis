// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Mantis",
    defaultLocalization: "en",
    platforms: [.iOS(.v15), .macCatalyst(.v15)],
    products: [
        .library(
            name: "Mantis",
            targets: ["Mantis"])
    ],
    targets: [
        .target(
            name: "Mantis",
            resources: [.process("Resources"), .copy("PrivacyInfo.xcprivacy")]
        ),
        .testTarget(
            name: "MantisTests",
            dependencies: ["Mantis"],
            path: "Tests/MantisTests"
        )
    ]
)
