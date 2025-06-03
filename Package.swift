// swift-tools-version: 6.0

import PackageDescription

let package = Package(
  name: "ChessKit",
  platforms: [
    .iOS(.v12),
    .macCatalyst(.v13),
    .macOS(.v10_13),
    .tvOS(.v12),
    .watchOS(.v4),
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
