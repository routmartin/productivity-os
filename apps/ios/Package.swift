// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ProductivityOS",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "ProductivityOS",
            targets: ["ProductivityOS"]
        ),
        .executable(
            name: "ProductivityOSMac",
            targets: ["ProductivityOSMac"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "ProductivityOS",
            dependencies: [],
            path: "ProductivityOS",
            exclude: [
                "Resources/Info.plist",
                "Resources/Assets.xcassets",
                "App/ProductivityOSApp.swift"
            ]
        ),
        .executableTarget(
            name: "ProductivityOSMac",
            dependencies: ["ProductivityOS"],
            path: "MacCompanion",
            exclude: ["Info.plist"]
        ),
        .testTarget(
            name: "ProductivityOSTests",
            dependencies: ["ProductivityOS"],
            path: "ProductivityOSTests"
        ),
    ]
)
