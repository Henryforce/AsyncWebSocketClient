// swift-tools-version:6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "AsyncWebSocketClient",
  platforms: [.iOS(.v13), .macOS(.v12), .watchOS(.v6), .tvOS(.v13)],
  products: [
    // Products define the executables and libraries a package produces, and make them visible to other packages.
    .library(
      name: "AsyncWebSocketClient",
      targets: ["AsyncWebSocketClient"]),
    .library(
      name: "AsyncWebSocketClientMocks",
      targets: ["AsyncWebSocketClientMocks"]),
  ],
  dependencies: [
    // Dependencies declare other packages that this package depends on.
    .package(url: "https://github.com/Henryforce/AsyncTimeSequences", from: "0.0.9")
  ],
  targets: [
    // Targets are the basic building blocks of a package. A target can define a module or a test suite.
    // Targets can depend on other targets in this package, and on products in packages this package depends on.
    .target(
      name: "AsyncWebSocketClient",
      dependencies: [
        "AsyncTimeSequences"
      ]),
    .target(
      name: "AsyncWebSocketClientMocks",
      dependencies: [
        "AsyncWebSocketClient"
      ]),
    .testTarget(
      name: "AsyncWebSocketClientTests",
      dependencies: [
        "AsyncWebSocketClient",
        "AsyncTimeSequences",
        .product(name: "AsyncTimeSequencesSupport", package: "AsyncTimeSequences"),
      ]),
  ]
)
