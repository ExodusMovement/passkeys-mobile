// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Passkeys",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "Passkeys",
            targets: ["Passkeys"]),
    ],
    targets: [
        .target(
            name: "Passkeys"),

    ]
)
