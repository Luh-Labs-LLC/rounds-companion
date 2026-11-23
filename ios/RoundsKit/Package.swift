// swift-tools-version: 6.0
// Pure-Swift round logic (shot records, shorthand parser, round stats).
// No Firebase or UI, so CI can run its tests with `swift test` on macOS.
import PackageDescription

let package = Package(
    name: "RoundsKit",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "RoundsKit", targets: ["RoundsKit"]),
    ],
    targets: [
        .target(name: "RoundsKit"),
        .testTarget(name: "RoundsKitTests", dependencies: ["RoundsKit"]),
    ]
)
