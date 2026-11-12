//
//  ReferenceAndAIServiceTests.swift
//  RigAssistCoreTests
//
//  Leonel's contribution: Verify offline filtering, grounding, and AI fallbacks.
//

import XCTest
@testable import RigAssistCore

final class ReferenceAndAIServiceTests: XCTestCase {
    func testReferenceServiceReturnsOnlyVerifiedRecordsOffline() {
        let approved = record(id: "REF-001", status: .verified, topic: "Sling angle")
        let unverified = record(id: "REF-002", status: .unverified, topic: "Sling inspection")
        let service = LocalReferenceService(
            dataset: dataset(records: [approved, unverified])
        )

        XCTAssertEqual(service.record(id: "ref-001"), approved)
        XCTAssertNil(service.record(id: "REF-002"))
        XCTAssertEqual(service.search(query: "SLING ANGLE", limit: 10), [approved])
    }

    func testBundledDatasetDecodesOfflineAndUnverifiedRecordsStayHidden() throws {
        let repositoryRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let dataURL = repositoryRoot.appendingPathComponent("data/reference_records.json")
        let data = try Data(contentsOf: dataURL)
        let dataset = try ReferenceDataLoader.decode(data)
        let service = LocalReferenceService(dataset: dataset)

        XCTAssertEqual(service.disclaimer, dataset.disclaimer)
        XCTAssertTrue(service.search(query: "sling", limit: 50).isEmpty)
    }

    func testReferenceSearchNormalizesQueriesAndHonorsLimit() {
        let first = record(id: "REF-001", status: .verified, topic: "Sling angle")
        let second = record(id: "REF-002", status: .verified, topic: "Low sling angle")
        let service = LocalReferenceService(dataset: dataset(records: [second, first]))

        XCTAssertEqual(service.search(query: "  SLING-angle! ", limit: 1), [first])
        XCTAssertEqual(service.search(query: "sling", limit: 0), [])
        XCTAssertEqual(service.search(query: "  ", limit: 5), [])
    }

    func testAISearchRejectsRecordsMatchingOnlyABroadSharedWord() {
        let unrelated = record(
            id: "REF-001",
            status: .verified,
            topic: "Sling inspection",
            tags: ["sling configuration", "visual inspection"]
        )
        let service = LocalReferenceService(dataset: dataset(records: [unrelated]))

        XCTAssertEqual(service.search(query: "sling angle", limit: 10), [unrelated])
        XCTAssertTrue(service.searchForAI(query: "sling angle", limit: 3).isEmpty)
    }

    func testAIProviderDoesNotReceiveBroadlyMatchedUnrelatedRecords() async {
        let unrelated = record(
            id: "REF-001",
            status: .verified,
            topic: "Sling inspection",
            tags: ["sling configuration", "visual inspection"]
        )
        let ai = ConstrainedAIService(
            referenceService: LocalReferenceService(
                dataset: dataset(records: [unrelated])
            ),
            provider: StubAIProvider(
                result: .success(
                    AIProviderAnswer(
                        text: "This answer must not be used.",
                        citedRecordIDs: [unrelated.id]
                    )
                )
            )
        )

        let response = await ai.ask("sling angle")

        XCTAssertTrue(response.isFallback)
        XCTAssertTrue(response.sources.isEmpty)
        XCTAssertTrue(response.answer.contains("could not find a verified local reference"))
    }

    func testAIWithoutMatchingVerifiedMaterialFallsBackWithoutSources() async {
        let service = LocalReferenceService(
            dataset: dataset(records: [
                record(id: "REF-001", status: .unverified, topic: "Sling angle")
            ])
        )
        let response = await ConstrainedAIService(referenceService: service)
            .ask("sling angle")

        XCTAssertTrue(response.isFallback)
        XCTAssertTrue(response.sources.isEmpty)
        XCTAssertNotNil(response.fallbackReason)
        XCTAssertTrue(response.answer.contains("verified local reference"))
    }

    func testAIUsesProviderOnlyWithVerifiedSources() async {
        let approved = record(id: "REF-001", status: .verified, topic: "Sling angle")
        let service = LocalReferenceService(dataset: dataset(records: [
            approved,
            record(id: "REF-002", status: .unverified, topic: "Sling angle inspection")
        ]))
        let ai = ConstrainedAIService(
            referenceService: service,
            provider: StubAIProvider(
                result: .success(
                    AIProviderAnswer(
                        text: "Grounded answer.",
                        citedRecordIDs: [approved.id]
                    )
                )
            )
        )

        let response = await ai.ask("sling angle")

        XCTAssertEqual(response.answer, "Grounded answer.")
        XCTAssertFalse(response.isFallback)
        XCTAssertEqual(response.sources, [approved])
        XCTAssertNil(response.fallbackReason)
    }

    func testProviderFailureFallsBackToOfflineReferenceText() async {
        let approved = record(id: "REF-001", status: .verified, topic: "Sling angle")
        let service = LocalReferenceService(dataset: dataset(records: [approved]))
        let ai = ConstrainedAIService(
            referenceService: service,
            provider: StubAIProvider(result: .failure(.unavailable))
        )

        let response = await ai.ask("sling angle")

        XCTAssertTrue(response.isFallback)
        XCTAssertEqual(response.sources, [approved])
        XCTAssertTrue(response.answer.contains(approved.summary))
        XCTAssertTrue(response.fallbackReason?.contains("unavailable") == true)
    }

    func testMissingProviderUsesOfflineReferenceText() async {
        let approved = record(id: "REF-001", status: .verified, topic: "Sling angle")
        let service = LocalReferenceService(dataset: dataset(records: [approved]))

        let response = await ConstrainedAIService(referenceService: service)
            .ask("sling angle")

        XCTAssertTrue(response.isFallback)
        XCTAssertEqual(response.sources, [approved])
        XCTAssertTrue(response.answer.contains(approved.summary))
        XCTAssertTrue(response.fallbackReason?.contains("not configured") == true)
    }

    func testEmptyProviderResponseUsesOfflineReferenceText() async {
        let approved = record(id: "REF-001", status: .verified, topic: "Sling angle")
        let service = LocalReferenceService(dataset: dataset(records: [approved]))
        let ai = ConstrainedAIService(
            referenceService: service,
            provider: StubAIProvider(
                result: .success(AIProviderAnswer(text: " \n ", citedRecordIDs: [approved.id]))
            )
        )

        let response = await ai.ask("sling angle")

        XCTAssertTrue(response.isFallback)
        XCTAssertEqual(response.sources, [approved])
        XCTAssertTrue(response.answer.contains(approved.summary))
    }

    func testEmptyQuestionGetsControlledFallback() async {
        let service = LocalReferenceService(dataset: dataset(records: []))
        let response = await ConstrainedAIService(referenceService: service).ask("   ")

        XCTAssertTrue(response.isFallback)
        XCTAssertTrue(response.sources.isEmpty)
        XCTAssertTrue(response.answer.contains("Enter a question"))
    }

    func testCalculationQuestionIsNotSentToAIProvider() async {
        let approved = record(id: "REF-001", status: .verified, topic: "Sling angle")
        let service = LocalReferenceService(dataset: dataset(records: [approved]))
        let ai = ConstrainedAIService(
            referenceService: service,
            provider: StubAIProvider(
                result: .success(
                    AIProviderAnswer(
                        text: "This answer must not be used.",
                        citedRecordIDs: [approved.id]
                    )
                )
            )
        )

        for question in [
            "Calculate the tension per leg for a 5000 lb load",
            "Determine sling tension for a 5,000 lb load at 45 degrees",
            "What would each leg carry at 30 degrees?",
            "5,000 lb load at 45 degrees — tension per leg?"
        ] {
            let response = await ai.ask(question)

            XCTAssertTrue(response.isFallback, question)
            XCTAssertTrue(response.sources.isEmpty, question)
            XCTAssertTrue(response.answer.contains("deterministic Calculator"), question)
        }
    }

    func testAIRejectsRecordsWithoutCompleteReviewAndSourceMetadata() {
        let incompleteRecords = [
            record(
                id: "REF-001",
                status: .verified,
                topic: "Sling angle",
                reviewedBy: nil
            ),
            record(
                id: "REF-002",
                status: .verified,
                topic: "Sling angle",
                reviewedOn: nil
            ),
            record(
                id: "REF-003",
                status: .verified,
                topic: "Sling angle",
                sourceEdition: "TO VERIFY"
            ),
            record(
                id: "REF-004",
                status: .verified,
                topic: "Sling angle",
                sourceSection: " "
            ),
            record(
                id: "REF-005",
                status: .verified,
                topic: "Sling angle",
                reviewedOn: "2026-02-30"
            )
        ]
        let service = LocalReferenceService(dataset: dataset(records: incompleteRecords))

        XCTAssertTrue(service.search(query: "sling angle", limit: 10).isEmpty)
    }

    func testProviderCannotCiteRecordsOutsideVerifiedContext() async {
        let approved = record(id: "REF-001", status: .verified, topic: "Sling angle")
        let service = LocalReferenceService(dataset: dataset(records: [approved]))
        let ai = ConstrainedAIService(
            referenceService: service,
            provider: StubAIProvider(
                result: .success(
                    AIProviderAnswer(
                        text: "Unsupported answer.",
                        citedRecordIDs: ["REF-999"]
                    )
                )
            )
        )

        let response = await ai.ask("sling angle")

        XCTAssertTrue(response.isFallback)
        XCTAssertEqual(response.sources, [approved])
        XCTAssertTrue(response.answer.contains(approved.summary))
    }

    private func dataset(records: [ReferenceRecord]) -> ReferenceDataset {
        ReferenceDataset(
            schemaVersion: "1.0",
            datasetVersion: "test",
            disclaimer: "Test-only reference disclaimer.",
            records: records
        )
    }

    private func record(
        id: String,
        status: ReferenceRecord.Verification.Status,
        topic: String,
        tags: [String] = ["sling angle", "load angle"],
        reviewedBy: String? = "Test reviewer",
        reviewedOn: String? = "2026-01-01",
        sourceEdition: String = "Test edition",
        sourceSection: String = "Test section"
    ) -> ReferenceRecord {
        ReferenceRecord(
            id: id,
            topic: topic,
            category: .loadAngle,
            tags: tags,
            summary: "Approved summary for \(topic).",
            aiContext: "Approved AI context for \(topic).",
            relatedCalculation: nil,
            source: .init(
                title: "Test source",
                publisher: "Test publisher",
                edition: sourceEdition,
                section: sourceSection
            ),
            verification: .init(
                status: status,
                reviewedBy: status == .verified ? reviewedBy : nil,
                reviewedOn: status == .verified ? reviewedOn : nil
            )
        )
    }
}

private struct StubAIProvider: AIAnswerProviding {
    let result: Result<AIProviderAnswer, AIProviderError>

    func answer(
        question: String,
        using records: [ReferenceRecord]
    ) async throws -> AIProviderAnswer {
        try result.get()
    }
}
