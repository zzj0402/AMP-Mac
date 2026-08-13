// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AMPApp",
    platforms: [
        .macOS(.v13),
        .iOS(.v16)
    ],
    products: [
        .library(name: "AMPShared", targets: ["AMPShared"]),
        .executable(name: "AMPApp", targets: ["AMPApp"]),
        .executable(name: "AMPiOSApp", targets: ["AMPiOSApp"])
    ],
    dependencies: [
        .package(url: "https://github.com/stephencelis/SQLite.swift.git", from: "0.14.0")
    ],
    targets: [
        .target(
            name: "AMPShared",
            dependencies: [
                .product(name: "SQLite", package: "SQLite.swift")
            ],
            path: "Sources/AMPShared"
        ),
        .executableTarget(
            name: "AMPApp",
            dependencies: [
                "AMPShared"
            ],
            path: "Sources/AMPAppMacOS"
        ),
        .executableTarget(
            name: "AMPiOSApp",
            dependencies: [
                "AMPShared"
            ],
            path: "Sources/AMPiOS"
        )
    ]
)
