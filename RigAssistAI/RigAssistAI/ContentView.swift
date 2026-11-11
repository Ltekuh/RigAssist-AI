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

    /// Reference service used by the Reference Library interface.
    ///
    /// MockReferenceService is used during interface development so the
    /// Reference UI can be developed independently from the production
    /// local reference service.
    private let referenceService: any ReferenceServiceProtocol =
        MockReferenceService()

    /// AI service used by the Ask AI interface.
    ///
    /// MockAIService allows the complete assistant interface to be tested
    /// before the production constrained AI service is integrated.
    private let aiService: any AIServiceProtocol =
        MockAIService()

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

            ReferenceLibraryView(
                referenceService: referenceService
            )
            .tabItem {
                Label(
                    "Reference",
                    systemImage: "books.vertical.fill"
                )
            }

            // MARK: Ask AI

            AskAIView(
                aiService: aiService
            )
            .tabItem {
                Label(
                    "Ask AI",
                    systemImage: "sparkles"
                )
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}
