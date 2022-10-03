// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "Library",
    platforms: [
        .iOS(.v16),
        .macCatalyst(.v16),
    ],
    products: [
        .library(
            name: "App",
            targets: [
                "BenoteModel"
            ]),
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture", branch: "protocol"),
    ],
    targets: [
        .target(
            name: "BenoteModel",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
            ]),
        .testTarget(
            name: "BenoteModelTests",
            dependencies: ["BenoteModel"]),
    ]
)
