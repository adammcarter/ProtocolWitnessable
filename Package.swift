// swift-tools-version: 5.10

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "ProtocolWitnessing",
    platforms: [.macOS(.v12), .iOS(.v13), .tvOS(.v13), .watchOS(.v6), .macCatalyst(.v13)],
    products: [
        .library(
            name: "ProtocolWitnessing",
            targets: ["ProtocolWitnessing"]
        ),
        .executable(
            name: "ProtocolWitnessingClient",
            targets: ["ProtocolWitnessingClient"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-syntax.git", from: "509.0.0"),
        .package(url: "https://github.com/pointfreeco/swift-macro-testing.git", from: "0.3.0"),
    ],
    targets: [
        .macro(
            name: "ProtocolWitnessingMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ]
        ),
        .target(name: "ProtocolWitnessing", dependencies: ["ProtocolWitnessingMacros"]),
        .executableTarget(name: "ProtocolWitnessingClient", dependencies: ["ProtocolWitnessing"]),
        .testTarget(
            name: "ProtocolWitnessingTests",
            dependencies: [
                "ProtocolWitnessingMacros",
                .product(name: "MacroTesting", package: "swift-macro-testing"),
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
            ]
        ),
    ]
)
