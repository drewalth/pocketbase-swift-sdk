// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "pocketbase-swift-sdk",
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "pocketbase-swift-sdk",
            targets: ["pocketbase-swift-sdk"]),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "pocketbase-swift-sdk"),
        .testTarget(
            name: "pocketbase-swift-sdkTests",
            dependencies: ["pocketbase-swift-sdk"]
        ),
    ]
)
