// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "RigAssistCore",
    platforms: [
        .macOS(.v13),
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "RigAssistCore",
            targets: ["RigAssistCore"]
        ),
    ],
    targets: [
        .target(
            name: "RigAssistCore",
            path: "RigAssistAI/RigAssistAI",
            exclude: [
                "Assets.xcassets",
                "ContentView.swift",
                "Design",
                "Models/CalculationError.swift",
                "Models/CalculationResult.swift",
                "RigAssistAIApp.swift",
                "Services",
                "Views"
            ],
            sources: [
                "ReferenceRecord.swift",
                "Models/LiftInput.swift"
            ]
        ),
        .testTarget(
            name: "RigAssistCoreTests",
            dependencies: ["RigAssistCore"],
            path: "Tests/RigAssistCoreTests"
        ),
    ]
)