// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SvatekTracker",
    platforms: [
        .macOS(.v14),
    ],
    targets: [
        // Pure, dependency-free logic — the name-day calendar, public holidays,
        // reminder planning, and Czech wording. 100% unit-testable.
        .target(
            name: "SvatekTrackerCore"
        ),
        // The menubar app: AppKit / SwiftUI / UserNotifications live here.
        .executableTarget(
            name: "SvatekTracker",
            dependencies: ["SvatekTrackerCore"]
        ),
        .testTarget(
            name: "SvatekTrackerCoreTests",
            dependencies: ["SvatekTrackerCore"]
        ),
    ]
)
