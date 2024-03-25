// swift-tools-version: 5.10

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "ProtocolWitnessable",
    platforms: [.macOS(.v12), .iOS(.v13), .tvOS(.v13), .watchOS(.v6), .macCatalyst(.v13)],
    products: [
        .library(
            name: "ProtocolWitnessable",
            targets: ["ProtocolWitnessable"]
        ),
        .executable(
            name: "ProtocolWitnessableClient",
            targets: ["ProtocolWitnessableClient"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-syntax.git", .upToNextMajor(from: "510.0.1")),
        .package(url: "https://github.com/pointfreeco/swift-macro-testing.git", exact: "0.3.0"),
    ],
    targets: [
        .macro(
            name: "ProtocolWitnessableMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ]
        ),
        .target(name: "ProtocolWitnessable", dependencies: ["ProtocolWitnessableMacros"]),
        .executableTarget(name: "ProtocolWitnessableClient", dependencies: ["ProtocolWitnessable"]),
        .testTarget(
            name: "ProtocolWitnessableTests",
            dependencies: [
                "ProtocolWitnessableMacros",
                .product(name: "MacroTesting", package: "swift-macro-testing"),
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
            ]
        ),
    ]
)
