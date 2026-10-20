// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "StrengthLabModule",
    platforms: [.iOS("18.0")],
    products: [
        .library(name: "StrengthLabModule", targets: ["StrengthLabModule"])
    ],
    dependencies: [
        .package(url: "https://github.com/alexeichhorn/YouTubeKit.git", exact: "0.4.9")
    ],
    targets: [
        .target(
            name: "StrengthLabModule",
            dependencies: [.product(name: "YouTubeKit", package: "YouTubeKit")],
            path: "Sources/StrengthLabModule",
            resources: [.process("Assets.xcassets"), .copy("Resources/ExerciseDB")]
        )
    ]
)
