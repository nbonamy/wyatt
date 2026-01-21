// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Wyatt",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "Wyatt",
            path: "Sources"
        )
    ]
)
