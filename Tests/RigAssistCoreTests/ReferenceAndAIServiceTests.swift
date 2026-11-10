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

        let response = await ai.ask("Calculate the tension per leg for a 5000 lb load")

        XCTAssertTrue(response.isFallback)
        XCTAssertTrue(response.sources.isEmpty)
        XCTAssertTrue(response.answer.contains("deterministic Calculator"))
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
        topic: String
    ) -> ReferenceRecord {
        ReferenceRecord(
            id: id,
            topic: topic,
            category: .loadAngle,
            tags: ["sling angle", "load angle"],
            summary: "Approved summary for \(topic).",
            aiContext: "Approved AI context for \(topic).",
            relatedCalculation: nil,
            source: .init(
                title: "Test source",
                publisher: "Test publisher",
                edition: "Test edition",
                section: "Test section"
            ),
            verification: .init(
                status: status,
                reviewedBy: status == .verified ? "Test reviewer" : nil,
                reviewedOn: status == .verified ? "2026-01-01" : nil
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
