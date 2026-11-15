//
//  MockAIService.swift
//  RigAssistAI
//
//  Created by Macauley Wain on 11/11/26.
//
//  UI-only mock implementation of AIServiceProtocol.
//
//  This service allows the Ask AI interface to be designed and tested
//  independently from the production ConstrainedAIService.
//
//  IMPORTANT:
//  - This mock does not contact an external AI provider.
//  - It does not perform rigging calculations.
//  - It must not be treated as a source of safety-critical information.
//

import Foundation

struct MockAIService: AIServiceProtocol {

    // MARK: - Ask AI

    /// Returns a simulated Assistant response for interface development.
    ///
    /// The production application will replace this mock with the
    /// constrained AI service supplied by the integration layer.
    func ask(_ question: String) async -> AssistantResponse {

        // Remove surrounding whitespace before evaluating the question.
        let trimmedQuestion = question.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        // Prevent an empty prompt from producing a simulated response.
        guard !trimmedQuestion.isEmpty else {
            return AssistantResponse(
                answer: "Enter a rigging question to continue.",
                isFallback: true,
                sources: [],
                fallbackReason: "No question was entered."
            )
        }

        // Simulate a short delay so the interface can exercise its
        // loading state while waiting for an asynchronous service.
        try? await Task.sleep(
            for: .milliseconds(650)
        )

        // Calculation requests are intentionally rejected by the mock.
        // Safety-critical calculations belong exclusively to the
        // deterministic Calculation Engine.
        if appearsToRequestCalculation(trimmedQuestion) {
            return AssistantResponse(
                answer: """
                RigAssist AI does not perform lifting calculations. \
                Use the Calculator for deterministic load and sling \
                calculations.
                """,
                isFallback: true,
                sources: [],
                fallbackReason: "Calculation requests must use the Calculator."
            )
        }

        // Return a controlled sample explanation for UI development.
        //
        // No ReferenceRecord is attached here because the mock should not
        // represent sample content as an approved or verified source.
        return AssistantResponse(
            answer: """
            Sling angle can affect the force carried by each sling leg. \
            As the sling angle becomes lower, the force on each leg can \
            increase. Use the Reference Library for approved source \
            information and the Calculator for deterministic calculations.
            """,
            isFallback: false,
            sources: [],
            fallbackReason: nil
        )
    }

    // MARK: - Mock Safety Boundary

    /// Provides a lightweight UI-development guard against obvious
    /// calculation requests.
    ///
    /// This is not the production AI safety implementation. The real
    /// ConstrainedAIService remains responsible for enforcing the
    /// application's AI/calculation boundary.
    private func appearsToRequestCalculation(_ question: String) -> Bool {

        let normalizedQuestion = question.lowercased()

        let calculationTerms = [
            "calculate",
            "compute",
            "determine the tension",
            "find the tension",
            "tension per leg",
            "load per leg",
            "how much tension",
            "how much load",
            "what is the tension",
            "what's the tension"
        ]

        return calculationTerms.contains { term in
            normalizedQuestion.contains(term)
        }
    }
}
