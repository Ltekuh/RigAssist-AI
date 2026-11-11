//
//  AskAIView.swift
//  RigAssistAI
//
//  Created by Macauley Wain on 11/11/26.
//
//  User-facing interface for the RigAssist AI assistant.
//
//  The view communicates only through AIServiceProtocol so the interface
//  remains independent from the concrete AI implementation.
//
//  IMPORTANT:
//  RigAssist AI provides explanatory assistance only. Safety-critical
//  calculations remain the responsibility of the deterministic Calculator.
//

import SwiftUI

struct AskAIView: View {

    // MARK: - Dependencies

    /// AI service supplied to the interface.
    ///
    /// During interface development this can be MockAIService.
    /// The production ConstrainedAIService can later be injected without
    /// requiring the user interface to know how that service is implemented.
    let aiService: any AIServiceProtocol

    // MARK: - State

    /// Question currently entered by the user.
    @State private var question = ""

    /// Most recent response returned by the AI service.
    @State private var response: AssistantResponse?

    /// Controls the loading state while an asynchronous request is running.
    @State private var isLoading = false

    /// Tracks keyboard focus for the question field.
    @FocusState private var questionFieldIsFocused: Bool

    // MARK: - Suggested Questions

    /// Example prompts help demonstrate the intended explanatory scope
    /// of the assistant without encouraging calculation requests.
    private let suggestedQuestions = [
        "How does sling angle affect tension?",
        "What should I inspect before using a sling?",
        "Why is sling configuration important?"
    ]

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {

                    headerSection

                    safetyNotice

                    questionSection

                    if response == nil && !isLoading {
                        suggestedQuestionsSection
                    }

                    if isLoading {
                        loadingSection
                    }

                    if let response {
                        responseSection(response)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)

                // Extra space prevents the final content from being
                // obscured by the application's floating tab bar.
                .padding(.bottom, 110)
            }
            .background(RigAssistTheme.background)
            .navigationTitle("Ask RigAssist AI")
            .navigationBarTitleDisplayMode(.inline)
            .onTapGesture {
                questionFieldIsFocused = false
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Rigging Guidance Assistant")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(RigAssistTheme.primaryText)

            Text(
                "Ask questions about supported rigging concepts and approved reference information."
            )
            .font(.subheadline)
            .foregroundStyle(RigAssistTheme.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Safety Notice

    private var safetyNotice: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(RigAssistTheme.warning)
                .font(.system(size: 17, weight: .semibold))

            VStack(alignment: .leading, spacing: 4) {
                Text("AI Guidance Only")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(RigAssistTheme.primaryText)

                Text(
                    "RigAssist AI explains approved reference information. " +
                    "Use the Calculator for deterministic lifting calculations."
                )
                .font(.caption)
                .foregroundStyle(RigAssistTheme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(
                cornerRadius: RigAssistTheme.cardCornerRadius
            )
            .fill(RigAssistTheme.cardBackground)
        )
    }

    // MARK: - Question Entry

    private var questionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Ask a Question")
                .font(.headline)
                .foregroundStyle(RigAssistTheme.primaryText)

            HStack(alignment: .bottom, spacing: 10) {
                TextField(
                    "Ask about a rigging topic...",
                    text: $question,
                    axis: .vertical
                )
                .lineLimit(2...5)
                .focused($questionFieldIsFocused)
                .accessibilityIdentifier("assistant.question")
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(
                        cornerRadius: RigAssistTheme.controlCornerRadius
                    )
                    .fill(RigAssistTheme.cardBackground)
                )

                Button {
                    submitQuestion()
                } label: {
                    if isLoading {
                        ProgressView()
                            .controlSize(.small)
                            .frame(width: 22, height: 22)
                    } else {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 16, weight: .bold))
                            .frame(width: 22, height: 22)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(
                    question.trimmingCharacters(
                        in: .whitespacesAndNewlines
                    ).isEmpty || isLoading
                )
                .accessibilityLabel("Ask")
            }
        }
    }

    // MARK: - Suggested Questions

    private var suggestedQuestionsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Suggested Questions")
                .font(.headline)
                .foregroundStyle(RigAssistTheme.primaryText)

            ForEach(suggestedQuestions, id: \.self) { suggestion in
                Button {
                    question = suggestion
                    submitQuestion()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "sparkles")
                            .foregroundStyle(RigAssistTheme.warning)

                        Text(suggestion)
                            .font(.subheadline)
                            .foregroundStyle(RigAssistTheme.primaryText)
                            .multilineTextAlignment(.leading)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(RigAssistTheme.secondaryText)
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(
                            cornerRadius: RigAssistTheme.cardCornerRadius
                        )
                        .fill(RigAssistTheme.cardBackground)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Loading State

    private var loadingSection: some View {
        HStack(spacing: 12) {
            ProgressView()

            VStack(alignment: .leading, spacing: 2) {
                Text("Reviewing approved references...")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(RigAssistTheme.primaryText)

                Text("RigAssist AI is preparing a response.")
                    .font(.caption)
                    .foregroundStyle(RigAssistTheme.secondaryText)
            }

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(
                cornerRadius: RigAssistTheme.cardCornerRadius
            )
            .fill(RigAssistTheme.cardBackground)
        )
    }

    // MARK: - Response

    private func responseSection(
        _ response: AssistantResponse
    ) -> some View {
        VStack(alignment: .leading, spacing: 16) {

            HStack(spacing: 8) {
                Image(
                    systemName: response.isFallback
                        ? "exclamationmark.circle.fill"
                        : "sparkles"
                )
                .foregroundStyle(
                    response.isFallback
                        ? RigAssistTheme.warning
                        : .green
                )

                Text(
                    response.isFallback
                        ? "RigAssist Notice"
                        : "RigAssist AI"
                )
                .font(.headline)
                .foregroundStyle(RigAssistTheme.primaryText)
            }

            Text(response.answer)
                .font(.body)
                .foregroundStyle(RigAssistTheme.primaryText)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("assistant.answer")

            // Display the reason when the service intentionally returned
            // a controlled fallback instead of an AI-generated explanation.
            if let fallbackReason = response.fallbackReason {
                Divider()

                VStack(alignment: .leading, spacing: 4) {
                    Text("Why this response was limited")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(RigAssistTheme.secondaryText)

                    Text(fallbackReason)
                        .font(.caption)
                        .foregroundStyle(RigAssistTheme.secondaryText)
                }
            }

            // Source attribution is shown only when the AI service returns
            // approved ReferenceRecord values with the response.
            if !response.sources.isEmpty {
                Divider()

                VStack(alignment: .leading, spacing: 10) {
                    Text("Sources")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(RigAssistTheme.primaryText)

                    ForEach(response.sources) { source in
                        sourceRow(source)
                    }
                }
            }

            Divider()

            Text(
                "Verify guidance against applicable standards, manufacturer " +
                "instructions, and the judgment of a qualified person."
            )
            .font(.caption)
            .foregroundStyle(RigAssistTheme.secondaryText)
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(
                cornerRadius: RigAssistTheme.cardCornerRadius
            )
            .fill(RigAssistTheme.cardBackground)
        )
    }

    // MARK: - Source Row

    private func sourceRow(
        _ source: ReferenceRecord
    ) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "checkmark.shield.fill")
                .foregroundStyle(.green)

            VStack(alignment: .leading, spacing: 3) {
                Text(source.topic)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(RigAssistTheme.primaryText)

                Text(source.source.title)
                    .font(.caption)
                    .foregroundStyle(RigAssistTheme.secondaryText)

                Text(
                    "\(source.source.publisher) • " +
                    "\(source.source.edition) • " +
                    "\(source.source.section)"
                )
                .font(.caption2)
                .foregroundStyle(RigAssistTheme.secondaryText)
            }
        }
    }

    // MARK: - Submit Question

    /// Sends the current question through AIServiceProtocol.
    ///
    /// The view does not determine whether a question is supported,
    /// calculate loads, or generate an answer itself. Those decisions
    /// remain inside the service layer.
    private func submitQuestion() {
        let trimmedQuestion = question.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !trimmedQuestion.isEmpty, !isLoading else {
            return
        }

        // Dismiss the keyboard and replace any previous response with
        // the loading state while the new question is being processed.
        questionFieldIsFocused = false
        response = nil
        isLoading = true

        Task {
            let serviceResponse = await aiService.ask(trimmedQuestion)

            await MainActor.run {
                response = serviceResponse

                // Clear the submitted question after the response has
                // been received. The response remains visible so the user
                // can review it while preparing another question.
                question = ""

                isLoading = false
            }
        }
    }
}

// MARK: - Preview

#Preview {
    AskAIView(
        aiService: MockAIService()
    )
}
