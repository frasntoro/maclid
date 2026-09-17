// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "MacLid",
    platforms: [.macOS(.v12)],
    targets: [
        .target(
            name: "IconArt",
            path: "Sources/IconArt"
        ),
        .executableTarget(
            name: "MacLid",
            dependencies: ["IconArt"],
            path: "Sources/MacLid"
        ),
        .executableTarget(
            name: "LidAngleProbe",
            path: "Sources/LidAngleProbe"
        ),
        .executableTarget(
            name: "IconGenerator",
            dependencies: ["IconArt"],
            path: "Sources/IconGenerator"
        )
    ]
)
