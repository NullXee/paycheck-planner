// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "paycheck-planner",
    platforms: [.iOS(.v18)],                                      // ← forces iOS
    products: [
        .app(                                                      // ← makes it an app, not CLI
            name: "paycheck-planner",
            targets: ["paycheck-planner"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "paycheck-planner",
            dependencies: [],
            swiftSettings: [
                .unsafeFlags(["-parse-as-library"])               // lets us use @main App
            ]
        )
    ]
)
