// swift-tools-version: 5.9
// Copyright 2026 The ThunderID Authors
// SPDX-License-Identifier: Apache-2.0
import Foundation
import PackageDescription

let playgroundDir = URL(fileURLWithPath: #filePath).deletingLastPathComponent()

// SwiftPM names a path dependency after its directory, so the products are looked up under the
// checkout's directory name ("ios-sdks" in CI, whatever the clone is called locally).
let sdkPackage = playgroundDir.deletingLastPathComponent().lastPathComponent.lowercased()

// Config.plist is gitignored, so only bundle it when a local copy exists.
let hasConfig = FileManager.default.fileExists(
    atPath: playgroundDir.appendingPathComponent("Sources/Config.plist").path
)

let appTarget: Target = .executableTarget(
    name: "Playground",
    dependencies: [
        .product(name: "ThunderID", package: sdkPackage),
        .product(name: "ThunderIDSwiftUI", package: sdkPackage)
    ],
    path: "Sources",
    exclude: ["Config.plist.example", "Playground.entitlements", "Assets.xcassets"],
    resources: hasConfig ? [.process("Config.plist")] : []
)

let package = Package(
    name: "Playground",
    platforms: [.iOS(.v16), .macOS(.v13)],
    dependencies: [
        // Always build against the SDK sources in this repository.
        .package(path: "..")
    ],
    targets: [appTarget]
)
