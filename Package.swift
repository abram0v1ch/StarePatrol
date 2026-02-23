// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "StarePatrol",
    platforms: [.macOS(.v14)],
    targets: [
        .target(
            name: "StarePatrolCore",
            path: "Sources",
            sources: ["TimerManager.swift"]
        ),
        .testTarget(
            name: "StarePatrolTests",
            dependencies: ["StarePatrolCore"],
            path: "Tests"
        )
    ]
)
