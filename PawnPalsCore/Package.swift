// swift-tools-version: 6.2

// PawnPalsCore holds all of PawnPals' chess logic: no UI, no SwiftUI, no SwiftData.
// Keeping it in its own package means its tests run in seconds with `swift test`,
// without launching a simulator.

import PackageDescription

let strictSettings: [SwiftSetting] = [
    // Warnings are errors: fix the cause instead of living with the warning.
    .treatAllWarnings(as: .error)
]

let package = Package(
    name: "PawnPalsCore",
    platforms: [
        .iOS(.v18),
        // macOS is listed so `swift test` can run the tests directly on the Mac.
        .macOS(.v15),
    ],
    products: [
        .library(name: "PawnPalsCore", targets: ["PawnPalsCore"])
    ],
    dependencies: [
        // Chess rules: legal moves, check, checkmate, FEN. The referee for every move.
        .package(url: "https://github.com/chesskit-app/chesskit-swift", from: "0.17.0")
    ],
    targets: [
        .target(
            name: "PawnPalsCore",
            dependencies: [
                .product(name: "ChessKit", package: "chesskit-swift")
            ],
            swiftSettings: strictSettings
        ),
        .testTarget(
            name: "PawnPalsCoreTests",
            dependencies: ["PawnPalsCore"],
            swiftSettings: strictSettings
        ),
    ]
)
