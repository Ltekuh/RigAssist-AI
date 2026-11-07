// swift-tools-version: 5.9
// Leonel's contribution: Cross-platform test target for Reference and AI service logic.
import PackageDescription

let package = Package(
    name: "RigAssistCore",
    platforms: [
        .macOS(.v13),
        .iOS(.v16)
    ],
    products: [
        .library(name: "RigAssistCore", targets: ["RigAssistCore"])
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
                "Services/CalculationEngineProtocol.swift",
                "Services/MockCalculationEngine.swift",
                "Views"
            ],
            sources: [
                "ReferenceRecord.swift",
                "Models/LiftInput.swift",
                "Services/AIServiceProtocol.swift",
                "Services/ConstrainedAIService.swift",
                "Services/LocalReferenceService.swift",
                "Services/ReferenceServiceProtocol.swift"
            ]
        ),
        .testTarget(
            name: "RigAssistCoreTests",
            dependencies: ["RigAssistCore"],
            path: "Tests/RigAssistCoreTests"
        )
    ]
)
