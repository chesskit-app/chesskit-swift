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
  dependencies: [
    .package(url: "http://github.com/dduan/Dye", from: "0.0.1")
  ],
  targets: [
    .target(name: "ChessKit"),
    .executableTarget(
      name: "chesskit-cli",
      dependencies: [
        "ChessKit",
        .product(name: "Dye", package: "dye")
      ]
    ),
    .testTarget(name: "ChessKitTests", dependencies: ["ChessKit"])
  ]
)
