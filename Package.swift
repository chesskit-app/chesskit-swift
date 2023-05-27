// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "ChessKit",
    platforms: [
        .iOS(.v16), .watchOS(.v9), .macOS(.v13), .tvOS(.v16)
    ],
    products: [
        .library(
            name: "ChessKit",
            targets: ["ChessKit"]
        )
    ],
    targets: [
        .target(
            name: "ChessKit",
            dependencies: []
        ),
        .testTarget(
            name: "ChessKitTests",
            dependencies: ["ChessKit"]
        ),
    ]
)
