// swift-tools-version: 5.9
// Shared test target for the calculation engine and Reference/AI services.
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
                "RigAssistAIApp.swift",
                "Services/MockCalculationEngine.swift",
                "Services/MockReferenceService.swift",
                "Views"
            ],
            sources: [
                "Models/CalculationError.swift",
                "Models/CalculationResult.swift",
                "Services/CalculationEngineProtocol.swift",
                "Services/CalculationEngine.swift",
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
