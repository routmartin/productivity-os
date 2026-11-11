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
        .library(
            name: "FocusWidgetShared",
            targets: ["FocusWidgetShared"]
        ),
        .executable(
            name: "ProductivityOSMac",
            targets: ["ProductivityOSMac"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "FocusWidgetShared",
            dependencies: [],
            path: "Shared"
        ),
        .target(
            name: "ProductivityOS",
            dependencies: ["FocusWidgetShared"],
            path: "ProductivityOS",
            exclude: [
                "Resources/Info.plist",
                "Resources/Assets.xcassets",
                "App/ProductivityOSApp.swift",
                "Resources/ProductivityOS.entitlements"
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
            dependencies: ["ProductivityOS", "FocusWidgetShared"],
            path: "ProductivityOSTests"
        ),
    ]
)
