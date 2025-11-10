// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "MacGuardianSuiteUI",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(name: "MacGuardianSuiteUI", targets: ["MacGuardianSuiteUI"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "MacGuardianSuiteUI",
            dependencies: [],
            path: "Sources"
        )
    ]
)
