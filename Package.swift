// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "StarePolice",
    platforms: [.macOS(.v14)],
    targets: [
        .target(
            name: "StarePoliceCore",
            path: "Sources",
            sources: ["TimerManager.swift"]
        ),
        .testTarget(
            name: "StarePoliceTests",
            dependencies: ["StarePoliceCore"],
            path: "Tests"
        )
    ]
)
