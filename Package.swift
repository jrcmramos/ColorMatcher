// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ColorMatcher",
    platforms: [
       .macOS(.v10_14)
    ],
    products: [
        .executable(name: "color-matcher", targets: ["App"]),
        .library(name: "Core", targets: ["Core"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/apple/swift-argument-parser", from: "0.0.5"),
        .package(url: "https://github.com/chenyunguiMilook/SwiftyXML.git", from: "3.0.2")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "App",
            dependencies: [
                "Core",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                "SwiftyXML"
        ]),
        .target(
            name: "Core",
            dependencies: [
                "SwiftyXML"
        ]),
        .testTarget(
            name: "ColorMatcherTests",
            dependencies: [
                "Core",
        ])
    ]
)
