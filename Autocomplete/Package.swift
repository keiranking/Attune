// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Autocomplete",
    platforms: [.iOS(.v16), .macOS(.v14)],
    products: [
        .library(
            name: "Autocomplete",
            targets: ["Autocomplete"]
        ),
    ],
    targets: [
        .target(
            name: "Autocomplete"
        ),
        .testTarget(
            name: "AutocompleteTests",
            dependencies: ["Autocomplete"]
        ),
    ]
)
