// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "TrackpadKit",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "TrackpadKit", targets: ["TrackpadKit"]),
        .executable(name: "trackpad-demo", targets: ["trackpad-demo"]),
    ],
    targets: [
        .target(name: "CMultitouch"),
        .target(name: "TrackpadKit", dependencies: ["CMultitouch"]),
        .executableTarget(name: "trackpad-demo", dependencies: ["TrackpadKit"]),
    ]
)
