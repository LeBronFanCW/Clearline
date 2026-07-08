// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Clearline",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "Clearline", targets: ["Clearline"])
    ],
    dependencies: [
        .package(url: "https://github.com/sparkle-project/Sparkle", exact: "2.9.2")
    ],
    targets: [
        .executableTarget(
            name: "Clearline",
            dependencies: [.product(name: "Sparkle", package: "Sparkle")]
        ),
        .testTarget(name: "ClearlineTests", dependencies: ["Clearline"])
    ]
)
