// swift-tools-version:5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "RealityUI",
  platforms: [.iOS(.v13), .macOS(.v10_15)],
  products: [
    .library(
      name: "RealityUI",
      targets: ["RealityUI"])
  ],
  dependencies: [],
  targets: [
    .target(name: "RealityUI", dependencies: []),
    .testTarget(name: "RealityUITests", dependencies: ["RealityUI"])
  ]
)
