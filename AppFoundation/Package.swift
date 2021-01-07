// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AppFoundation",
    platforms: [.iOS(.v13)],
    products: [
        .library(
            name: "AppFoundation",
            targets: ["AppFoundation"])
    ],
    dependencies: [
        .package(url: "https://github.com/Quick/Nimble.git", .upToNextMajor(from: "8.1.1"))
    ],
    targets: [
        .target(
            name: "AppFoundation",
            dependencies: []),
        .testTarget(
            name: "AppFoundationTests",
            dependencies: ["AppFoundation", "Nimble"])
    ],
    swiftLanguageVersions: [.v5]
)
