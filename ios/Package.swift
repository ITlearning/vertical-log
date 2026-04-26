// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "VerticalLog",
    platforms: [
        // iOS is the actual ship target. macOS is declared so SourceKit/SwiftPM
        // can type-check the SwiftUI code on macOS hosts without availability noise.
        // The Xcode app target only builds for iOS.
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "VerticalLog", targets: ["VerticalLog"])
    ],
    targets: [
        .target(
            name: "VerticalLog",
            path: "VerticalLog",
            // VerticalLogApp.swift contains @main and belongs to the Xcode app target,
            // not the library. Excluded so the library compiles cleanly.
            exclude: ["App/VerticalLogApp.swift"]
        ),
        .testTarget(
            name: "VerticalLogTests",
            dependencies: ["VerticalLog"],
            path: "VerticalLogTests"
        )
    ]
)
