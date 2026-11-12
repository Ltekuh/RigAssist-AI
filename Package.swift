// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "RigAssistCore",
    platforms: [.macOS(.v13), .iOS(.v16)],
    products: [.library(name: "RigAssistCore", targets: ["RigAssistCore"])],
    targets: [
        .target(
            name: "RigAssistCore",
            path: "RigAssistAI/RigAssistAI",
            exclude: [
                "Assets.xcassets", "ContentView.swift", "Design", "RigAssistAIApp.swift",
                "ReferenceRecord.swift", "Services/AIServiceProtocol.swift",
                "Services/ReferenceServiceProtocol.swift", "Services/MockCalculationEngine.swift", "Views"
            ],
            sources: [
                "Models/LiftInput.swift", "Models/CalculationError.swift",
                "Models/CalculationResult.swift", "Services/CalculationEngineProtocol.swift",
                "Services/CalculationEngine.swift"
            ]
        ),
        .testTarget(name: "RigAssistCoreTests", dependencies: ["RigAssistCore"],
                    path: "Tests/RigAssistCoreTests")
    ]
)
