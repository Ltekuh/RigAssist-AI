//
//  AskAIView.swift
//  RigAssistAI
//
//  Leonel's contribution: Present reference-grounded answers and safe fallbacks.
//

import SwiftUI

struct AskAIView: View {
    let aiService: any AIServiceProtocol
    let disclaimer: String

    @State private var question = ""
    @State private var response: AssistantResponse?
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: RigAssistTheme.sectionSpacing) {
                    Text(disclaimer)
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    Text(
                        "Ask about a verified reference topic. This assistant does not perform rigging calculations."
                    )
                    .font(.subheadline)

                    TextField("Enter your question", text: $question, axis: .vertical)
                        .lineLimit(3...6)
                        .textFieldStyle(.roundedBorder)
                        .accessibilityIdentifier("assistant.question")

                    Button(action: submitQuestion) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                            }
                            Text(isLoading ? "Finding an answer…" : "Ask")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(RigAssistTheme.navy)
                    .disabled(isLoading)

                    if let response {
                        responseCard(response)
                    }
                }
                .padding(RigAssistTheme.screenPadding)
            }
            .background(RigAssistTheme.background)
            .navigationTitle("Ask AI")
        }
    }

    private func submitQuestion() {
        isLoading = true
        response = nil
        Task {
            response = await aiService.ask(question)
            isLoading = false
        }
    }

    private func responseCard(_ response: AssistantResponse) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if response.isFallback {
                Label("Reference-only fallback", systemImage: "info.circle")
                    .font(.headline)
                    .foregroundStyle(RigAssistTheme.warning)
            }

            Text(response.answer)
                .accessibilityIdentifier("assistant.answer")

            if let fallbackReason = response.fallbackReason {
                Text(fallbackReason)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            if response.sources.isEmpty {
                Text("No verified source records were used.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                Divider()
                Text("Sources")
                    .font(.headline)
                ForEach(response.sources) { source in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(source.topic)
                            .font(.subheadline.weight(.semibold))
                        Text("\(source.source.title) — \(source.source.publisher)")
                        Text("\(source.source.edition), \(source.source.section)")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
        }
        .padding(RigAssistTheme.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white, in: RoundedRectangle(cornerRadius: RigAssistTheme.cardCornerRadius))
    }
}
