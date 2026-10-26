// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "vwo_fme_flutter_sdk",
    platforms: [
        .iOS("12.0")
    ],
    products: [
        .library(name: "vwo-fme-flutter-sdk", targets: ["vwo_fme_flutter_sdk"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework"),
        .package(
            url: "https://github.com/wingify/vwo-fme-ios-sdk.git",
            exact: "1.55.0"
        ),
    ],
    targets: [
        .target(
            name: "vwo_fme_flutter_sdk",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework"),
                .product(name: "VWO-FME", package: "vwo-fme-ios-sdk"),
            ],
            swiftSettings: [
                .define("VWO_FME_FLUTTER_SDK")
            ]
        )
    ]
)
