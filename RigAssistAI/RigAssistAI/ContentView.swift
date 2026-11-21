//
//  ContentView.swift
//  RigAssistAI
//
//  Created by Macauley Wain.
//
//  Root navigation view for the RigAssist AI application.
//
//  The application is organized into three primary user-facing modules:
//
//  1. Calculator
//     Provides deterministic rigging calculations.
//
//  2. Reference
//     Provides searchable, verified rigging reference information.
//
//  3. Ask AI
//     Provides explanatory assistance grounded in approved references.
//
//  Safety-critical calculations remain isolated from the AI assistant.
//

import SwiftUI

struct ContentView: View {

    // MARK: - Service Dependencies

    /// Production local reference service loaded from the bundled
    /// reference dataset.
    ///
    /// The service exposes only reference records that satisfy the
    /// project's verified-record requirements.
    @State private var referenceService: LocalReferenceService?

    /// Stores an error encountered while loading the bundled
    /// reference dataset.
    @State private var loadError: String?

    // MARK: - Body

    var body: some View {
        TabView {

            // MARK: Calculator

            CalculatorView()
                .tabItem {
                    Label(
                        "Calculator",
                        systemImage: "function"
                    )
                }

            // MARK: Reference Library

            if let referenceService {
                ReferenceLibraryView(
                    referenceService: referenceService
                )
                .tabItem {
                    Label(
                        "Reference",
                        systemImage: "books.vertical.fill"
                    )
                }
            } else {
                referenceServiceStatus
                    .tabItem {
                        Label(
                            "Reference",
                            systemImage: "books.vertical.fill"
                        )
                    }
            }

            // MARK: Ask AI

            if let referenceService {
                AskAIView(
                    aiService: ConstrainedAIService(
                        referenceService: referenceService,
                        provider: integrationTestProvider
                    ),
                    disclaimer: referenceService.disclaimer
                )
                .tabItem {
                    Label(
                        "Ask AI",
                        systemImage: "sparkles"
                    )
                }
            } else {
                referenceServiceStatus
                    .tabItem {
                        Label(
                            "Ask AI",
                            systemImage: "sparkles"
                        )
                    }
            }
        }
        .task {
            loadReferenceData()
        }
    }

    // MARK: - Reference Service Status

    /// Displays a loading state while the bundled reference data is being
    /// initialized and a user-facing error if initialization fails.
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

    // MARK: - Reference Data Loading

    /// Loads the bundled reference dataset once and initializes the
    /// production LocalReferenceService.
    ///
    /// Failure is surfaced to the user instead of silently falling back
    /// to mock or unverified reference information.
    private func loadReferenceData() {
        guard referenceService == nil, loadError == nil else {
            return
        }

        do {
            #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("--ui-testing-reference-flow") {
                referenceService = UITestIntegrationFixture.referenceService
                return
            }
            #endif
            referenceService = try LocalReferenceService(bundle: .main)
        } catch {
            loadError = error.localizedDescription
        }
    }

    private var integrationTestProvider: (any AIAnswerProviding)? {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--ui-testing-reference-flow") {
            return UITestIntegrationFixture.Provider(
                fail: ProcessInfo.processInfo.arguments.contains("--ui-testing-provider-failure")
            )
        }
        #endif
        return nil
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}
