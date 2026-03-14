// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "LoggerUtility",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "LoggerUtility",
            path: "Sources/LoggerUtility"
        ),
        .testTarget(
            name: "LoggerUtilityTests",
            dependencies: ["LoggerUtility"],
            path: "Tests/LoggerUtilityTests"
        )
    ]
)
