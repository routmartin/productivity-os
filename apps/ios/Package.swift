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
    ],
    dependencies: [],
    targets: [
        .target(
            name: "ProductivityOS",
            dependencies: [],
            path: "ProductivityOS",
            exclude: [
                "Resources/Info.plist",
                "App/ProductivityOSApp.swift"
            ]
        ),
        .testTarget(
            name: "ProductivityOSTests",
            dependencies: ["ProductivityOS"],
            path: "ProductivityOSTests"
        ),
    ]
)
