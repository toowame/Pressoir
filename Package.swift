// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Pressoir",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "PressoirCore", targets: ["PressoirCore"]),
        .executable(name: "PressoirApp", targets: ["PressoirApp"]),
    ],
    targets: [
        .target(name: "PressoirCore"),
        .executableTarget(
            name: "PressoirApp",
            dependencies: ["PressoirCore"],
            linkerSettings: [.linkedFramework("Carbon")]
        ),
        .testTarget(name: "PressoirCoreTests", dependencies: ["PressoirCore"]),
    ],
    swiftLanguageModes: [.v6]
)
