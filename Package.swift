// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Mantis",
    platforms: [.iOS(.v11), .macOS(.v10_15)],
    products: [
        .library(
            name: "Mantis",
            targets: ["Mantis"])
    ],
    targets: [
        .target(
            name: "Mantis",
            dependencies: [])
    ]
)
