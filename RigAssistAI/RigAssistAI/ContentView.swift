// Leonel's contribution: Connect the calculator with local reference and Ask AI screens.
import SwiftUI

/// Root view for the RigAssist AI application.
struct ContentView: View {
    @State private var referenceService: LocalReferenceService?
    @State private var loadError: String?

    var body: some View {
        TabView {
            CalculatorView()
                .tabItem {
                    Label("Calculator", systemImage: "function")
                }

            if let referenceService {
                ReferenceLibraryView(referenceService: referenceService)
                    .tabItem {
                        Label("Reference", systemImage: "books.vertical")
                    }

                AskAIView(
                    aiService: ConstrainedAIService(
                        referenceService: referenceService
                    ),
                    disclaimer: referenceService.disclaimer
                )
                .tabItem {
                    Label("Ask AI", systemImage: "bubble.left.and.text.bubble.right")
                }
            } else {
                referenceServiceStatus
                    .tabItem {
                        Label("Reference", systemImage: "books.vertical")
                    }

                referenceServiceStatus
                    .tabItem {
                        Label("Ask AI", systemImage: "bubble.left.and.text.bubble.right")
                    }
            }
        }
        .task {
            loadReferenceData()
        }
    }

    @ViewBuilder
    private var referenceServiceStatus: some View {
        if let loadError {
            ContentUnavailableView(
                "Reference data unavailable",
                systemImage: "exclamationmark.triangle",
                description: Text(loadError)
            )
        } else {
            ProgressView("Loading local reference data…")
        }
    }

    private func loadReferenceData() {
        guard referenceService == nil, loadError == nil else { return }
        do {
            referenceService = try LocalReferenceService(bundle: .main)
        } catch {
            loadError = error.localizedDescription
        }
    }
}

#Preview {
    ContentView()
}
