// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "DevServer",
    platforms: [.iOS(.v15)],
    products: [
        .library(
            name: "DevServer",
            targets: ["DevServerPlugin"])
    ],
    dependencies: [
        .package(url: "https://github.com/ionic-team/capacitor-swift-pm.git", from: "8.0.0")
    ],
    targets: [
        .target(
            name: "DevServerPlugin",
            dependencies: [
                .product(name: "Capacitor", package: "capacitor-swift-pm"),
                .product(name: "Cordova", package: "capacitor-swift-pm")
            ],
            path: "ios/Sources/DevServerPlugin"),
        .testTarget(
            name: "DevServerPluginTests",
            dependencies: ["DevServerPlugin"],
            path: "ios/Tests/DevServerPluginTests")
    ]
)