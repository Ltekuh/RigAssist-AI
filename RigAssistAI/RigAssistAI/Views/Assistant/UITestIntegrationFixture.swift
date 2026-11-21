#if DEBUG
import Foundation

// Synthetic data only; never used by a release build or the normal app launch.
enum UITestIntegrationFixture {
    static let referenceService = LocalReferenceService(dataset: ReferenceDataset(
        schemaVersion: "1.0",
        datasetVersion: "ui-test-only",
        disclaimer: "UI TEST DATA ONLY. Not a rigging reference.",
        records: [
            ReferenceRecord(
                id: "REF-900",
                topic: "Fixture topic alpha",
                category: .appScope,
                tags: ["fixture topic", "topic alpha"],
                summary: "Synthetic fixture summary.",
                aiContext: "Synthetic fixture context.",
                relatedCalculation: nil,
                source: .init(
                    title: "Synthetic test source",
                    publisher: "UI test fixture",
                    edition: "Test edition",
                    section: "Test section"
                ),
                verification: .init(
                    status: .verified,
                    reviewedBy: "Test fixture only",
                    reviewedOn: "2026-01-01"
                )
            )
        ]
    ))

    struct Provider: AIAnswerProviding {
        let fail: Bool

        func answer(
            question: String,
            using records: [ReferenceRecord]
        ) async throws -> AIProviderAnswer {
            guard !fail else { throw AIProviderError.unavailable }
            guard let record = records.first else { throw AIProviderError.invalidResponse }
            return AIProviderAnswer(text: record.aiContext, citedRecordIDs: [record.id])
        }
    }
}
#endif
