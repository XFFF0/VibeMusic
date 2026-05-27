// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "VibeMusic",
    platforms: [.iOS(.v16)],
    dependencies: [
        .package(url: "https://github.com/google/GoogleSignIn-iOS", from: "7.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "VibeMusic",
            dependencies: [
                .product(name: "GoogleSignIn", package: "GoogleSignIn-iOS"),
                .product(name: "GoogleSignInSwift", package: "GoogleSignIn-iOS"),
            ],
            path: "Sources/VibeMusic",
            resources: [
                .process("Info.plist"),
                .process("Resources"),
            ]
        ),
    ]
)
