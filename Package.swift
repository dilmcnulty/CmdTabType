// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "CmdTabType",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "CmdTabType",
            targets: ["CmdTabType"]
        )
    ],
    targets: [
        .executableTarget(
            name: "CmdTabType",
            path: "CmdTabType",
            resources: [
                .process("Assets.xcassets")
            ]
        )
    ]
)
