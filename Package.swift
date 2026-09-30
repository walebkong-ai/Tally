// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Solvry",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "solvry-site", targets: ["SolvrySite"])
    ],
    targets: [
        .executableTarget(
            name: "SolvrySite",
            path: "Sources/SolvrySite"
        )
    ]
)
