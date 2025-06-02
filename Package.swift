// swift-tools-version: 6.0

import PackageDescription

let package = Package(
  name: "ChessKit",
  platforms: [
    .iOS(.v13),
    .macCatalyst(.v13),
    .macOS(.v10_15),
    .tvOS(.v13),
    .watchOS(.v6),
    .visionOS(.v1)
  ],
  products: [
    .library(name: "ChessKit", targets: ["ChessKit"])
  ],
  targets: [
    .target(name: "ChessKit"),
    .testTarget(name: "ChessKitTests", dependencies: ["ChessKit"])
  ]
)
