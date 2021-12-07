// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Mantis",
    defaultLocalization: "en",
    platforms: [.iOS(.v11), .macOS(.v10_15)],
    products: [
        .library(
            name: "Mantis",
            targets: ["Mantis"])
    ],
    targets: [
        .target(
            name: "Mantis",
            exclude: ["Info.plist", "Resources/Info.plist"],
            resources: [.process("Resources")],
            swiftSettings: [.define("MANTIS_SPM")]
        )
    ]
)
