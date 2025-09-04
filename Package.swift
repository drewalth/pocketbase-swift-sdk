// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "PocketBase",
  platforms: [
    .iOS(.v17),
    .macOS(.v14),
  ],
  products: [
    // Products define the executables and libraries a package produces, making them visible to other packages.
    .library(
      name: "PocketBase",
      targets: ["PocketBase"]),
  ],
  dependencies: [
    .package(url: "https://github.com/Alamofire/Alamofire.git", .upToNextMajor(from: "5.10.1")),
    .package(url: "https://github.com/Recouse/EventSource.git", .upToNextMajor(from: "0.1.5")),
  ],
  targets: [
    // Targets are the basic building blocks of a package, defining a module or a test suite.
    // Targets can depend on other targets in this package and products from dependencies.
    .target(
      name: "PocketBase",
      dependencies: ["Alamofire", "EventSource"]),
    .testTarget(
      name: "PocketBaseTests",
      dependencies: ["PocketBase"]),
  ])
