// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "RealityUI",
  platforms: [.iOS(.v13), .macOS(.v10_15)],
  products: [
    .library(
      name: "RealityUI",
      targets: ["RealityUI", "RealityToolkit"])
  ],
  dependencies: [],
  targets: [
    .target(name: "RealityUI", dependencies: []),
    .target(name: "RealityToolkit")
//    .testTarget(name: "RealityUITests", dependencies: ["RealityUI"])
  ]
)
