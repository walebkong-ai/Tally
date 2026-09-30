// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Tallyo",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "tallyo-site", targets: ["TallyoSite"])
    ],
    targets: [
        .executableTarget(
            name: "TallyoSite",
            path: "Sources/TallyoSite"
        )
    ]
)
