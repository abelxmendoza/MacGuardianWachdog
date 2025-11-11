// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MacGuardianSuiteUI",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "MacGuardianSuiteUI", targets: ["MacGuardianSuiteUI"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "MacGuardianSuiteUI",
            dependencies: [],
            path: "Sources/MacGuardianSuiteUI"
        )
    ]
)
