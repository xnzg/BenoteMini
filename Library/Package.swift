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
                "App",
                "BenoteModel",
            ]),
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture", branch: "protocol"),
        .package(url: "https://github.com/pointfreeco/swift-identified-collections", .upToNextMinor(from: "0.4.0")),

    ],
    targets: [
        .target(
            name: "App",
            dependencies: [
                "BenoteModel",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
            ]),
        .target(
            name: "BenoteModel",
            dependencies: [
                .product(name: "IdentifiedCollections", package: "swift-identified-collections"),
            ]),
        .testTarget(
            name: "BenoteModelTests",
            dependencies: ["BenoteModel"]),
    ]
)
