//
//  ConstrainedAIService.swift
//  RigAssistAI
//
//  Leonel's contribution: Reference-grounded AI orchestration and safe fallbacks.
//

import Foundation

/// A provider answer must identify the verified records supporting its text.
struct AIProviderAnswer {
    let text: String
    let citedRecordIDs: [String]
}

/// Provider implementations must limit context to supplied records, cite their IDs,
/// abstain when those records do not answer, and never perform rigging calculations.
protocol AIAnswerProviding {
    func answer(
        question: String,
        using records: [ReferenceRecord]
    ) async throws -> AIProviderAnswer
}

enum AIProviderError: Error, LocalizedError {
    case unavailable
    case requestFailed
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .unavailable:
            return "The AI provider is unavailable."
        case .requestFailed:
            return "The AI provider request failed."
        case .invalidResponse:
            return "The AI provider returned an invalid response."
        }
    }
}

/// Applies reference retrieval before inference and returns approved local text on failure.
struct ConstrainedAIService: AIServiceProtocol {
    private let referenceService: any ReferenceServiceProtocol
    private let provider: (any AIAnswerProviding)?
    private let maximumSources = 3

    init(
        referenceService: any ReferenceServiceProtocol,
        provider: (any AIAnswerProviding)? = nil
    ) {
        self.referenceService = referenceService
        self.provider = provider
    }

    func ask(_ question: String) async -> AssistantResponse {
        guard !question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return fallback(
                answer: "Enter a question about a supported reference topic.",
                reason: "The question was empty.",
                sources: []
            )
        }

        guard !Self.requestsCalculation(question) else {
            return fallback(
                answer: "I do not perform rigging calculations. Use the deterministic "
                    + "Calculator and have a qualified person verify the result.",
                reason: "Calculation requests are outside the AI service's scope.",
                sources: []
            )
        }

        let sources = referenceService.searchForAI(
            query: question,
            limit: maximumSources
        )
        guard !sources.isEmpty else {
            return fallback(
                answer: "I could not find a verified local reference for that question. "
                    + "Check the applicable source or ask a qualified person.",
                reason: "No verified reference matched the question.",
                sources: []
            )
        }

        guard let provider else {
            return localReferenceFallback(
                sources,
                reason: "The AI provider is not configured; showing verified local references."
            )
        }

        do {
            let providerAnswer = try await provider.answer(
                question: question,
                using: sources
            )
            let answer = providerAnswer.text.trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            let citedIDs = Set(providerAnswer.citedRecordIDs)
            let allowedIDs = Set(sources.map(\.id))
            guard !answer.isEmpty,
                  !citedIDs.isEmpty,
                  citedIDs.isSubset(of: allowedIDs) else {
                return localReferenceFallback(
                    sources,
                    reason: "The AI provider returned an unsupported answer or citation."
                )
            }
            let citedSources = sources.filter { citedIDs.contains($0.id) }
            return AssistantResponse(
                answer: answer,
                isFallback: false,
                sources: citedSources,
                fallbackReason: nil
            )
        } catch let error as AIProviderError {
            return localReferenceFallback(
                sources,
                reason: "\(error.localizedDescription) Showing verified local references."
            )
        } catch {
            return localReferenceFallback(
                sources,
                reason: "The AI provider failed unexpectedly. Showing verified local references."
            )
        }
    }

    private func localReferenceFallback(
        _ sources: [ReferenceRecord],
        reason: String
    ) -> AssistantResponse {
        let answer = sources
            .map { "\($0.topic): \($0.summary)" }
            .joined(separator: "\n\n")
        return fallback(answer: answer, reason: reason, sources: sources)
    }

    private func fallback(
        answer: String,
        reason: String,
        sources: [ReferenceRecord]
    ) -> AssistantResponse {
        AssistantResponse(
            answer: answer,
            isFallback: true,
            sources: sources,
            fallbackReason: reason
        )
    }

    private static func requestsCalculation(_ question: String) -> Bool {
        let normalized = question.lowercased()
        let calculationPhrases = [
            "calculate",
            "compute",
            "solve for",
            "work out",
            "determine",
            "estimate",
            "figure out",
            "what is the tension",
            "what's the tension",
            "how much tension",
            "tension per leg for",
            "load per leg for",
            "leg load for",
            "each leg carry",
            "per leg carry"
        ]
        let calculationIntent = [
            "how much",
            "how many",
            "what would",
            "what will",
            "what is",
            "what's"
        ]
        let calculatedValues = [
            "tension",
            "load",
            "carry",
            "capacity",
            "force",
            "weight",
            "multiplier",
            "per leg"
        ]
        let numericCalculationTargets = [
            "tension",
            "per leg",
            "load share",
            "multiplier"
        ]
        let containsNumber = normalized.range(
            of: #"\d"#,
            options: .regularExpression
        ) != nil

        return calculationPhrases.contains(where: normalized.contains)
            || ["+", "=", "×", "÷"].contains(where: question.contains)
            || (containsNumber
                && calculationIntent.contains(where: normalized.contains)
                && calculatedValues.contains(where: normalized.contains))
            || (containsNumber
                && numericCalculationTargets.contains(where: normalized.contains))
    }
}
