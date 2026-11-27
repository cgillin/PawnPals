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
        // ChessKit is still 0.x, where minor releases can change its API, so we only
        // accept 0.17.x bug fixes. Move to 0.18 on purpose, in its own PR.
        .package(
            url: "https://github.com/chesskit-app/chesskit-swift",
            .upToNextMinor(from: "0.17.0")
        ),
        // Stockfish, packaged for iOS. Also 0.x, so the same rule: bug fixes only.
        .package(
            url: "https://github.com/chesskit-app/chesskit-engine",
            .upToNextMinor(from: "0.7.0")
        ),
    ],
    targets: [
        .target(
            name: "PawnPalsCore",
            dependencies: [
                .product(name: "ChessKit", package: "chesskit-swift"),
                .product(name: "ChessKitEngine", package: "chesskit-engine"),
            ],
            resources: [
                // Stockfish's neural networks. Not in git: scripts/fetch-stockfish-networks.sh
                // downloads them into this folder.
                .copy("Engine/Networks")
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
