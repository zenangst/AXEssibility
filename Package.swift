// swift-tools-version:5.6
import PackageDescription

let package = Package(
  name: "AXEssibility",
  platforms: [.macOS(.v12)],
  products: [
    .library(name: "AXEssibility", targets: ["AXEssibility"]),
  ],
  targets: [
    .target(
      name: "AXEssibility",
      dependencies: [])
  ]
)

