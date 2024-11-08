// swift-tools-version: 6.0
// The swift-tools-version declares the minimum
// version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CocoParser",
    platforms: [.macOS(.v14)],
    products: [
        .executable(
            name: "coco",
            targets: ["coco"]),
        .library(
            name: "CocoParser",
            targets: ["CocoParser"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.5.0"),
    ],
    targets: [
        .target(
            name: "CocoParser"
//            resources: [
//                .copy("Resources")
//            ]
        ),
        .executableTarget(
            name: "coco",
            dependencies: [
                "CocoParser",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
            ,swiftSettings: [
                // Enable whole module optimization
                .unsafeFlags(["-whole-module-optimization"], .when(configuration: .release)),
                // Optimize for size
                .unsafeFlags(["-Osize"], .when(configuration: .release)),
                // Strip all symbols
                .unsafeFlags(["-Xlinker", "-strip-all"], .when(configuration: .release)),
                // Enable dead code stripping
                .unsafeFlags(["-Xlinker", "-dead_strip"], .when(configuration: .release)),
                // Embed Bitcode (if necessary, optional)
                // .unsafeFlags(["-embed-bitcode"], .when(configuration: .release)),
            ]
        ),
        .testTarget(
            name: "CocoParserTests",
            dependencies: ["CocoParser"]
        ),
    ]
)
