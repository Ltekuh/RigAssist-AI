//
//  MockReferenceService.swift
//  RigAssistAI
//
//  Created by Macauley Wain on 11/11/26.
//
//  UI-development implementation of ReferenceServiceProtocol.
//  This service exists so the Reference Library and related interfaces
//  can be developed and tested independently from the production
//  LocalReferenceService.
//
//  The production application uses LocalReferenceService for approved
//  reference retrieval. This mock remains available only for isolated
//  interface development, previews, and testing.
//
//  IMPORTANT:
//  The records below are sample UI data only. They are not approved
//  rigging references and must never be treated as operational guidance.
//

import Foundation

struct MockReferenceService: ReferenceServiceProtocol {

    // MARK: - Dataset Disclaimer

    /// Development-only disclaimer for interfaces using this mock service.
    ///
    /// This disclaimer reinforces that mock reference content is intended
    /// only for interface development and must not be interpreted as
    /// approved operational guidance.
    let disclaimer =
        "Prototype reference information only. Always verify lifting requirements against applicable standards, manufacturer instructions, and a qualified person."

    // MARK: - Sample UI Records

    /// Sample records used only to exercise Reference Library presentation,
    /// searching, source attribution, empty-state behavior, and AI interface
    /// grounding during development.
    ///
    /// These records intentionally identify their source and reviewer as
    /// UI Preview so they cannot be confused with records supplied by the
    /// production reference dataset.
    private let records: [ReferenceRecord] = [

        ReferenceRecord(
            id: "REF-001",
            topic: "Sling Angle",
            category: .loadAngle,
            tags: ["sling angle", "load angle"],
            summary:
                "As the sling angle decreases, the tension carried by each sling leg increases.",
            aiContext:
                "Lower sling angles increase sling-leg tension. Use the deterministic calculator for calculations.",
            relatedCalculation: "slingAngle",
            source: .init(
                title: "Sample Rigging Reference",
                publisher: "RigAssist AI",
                edition: "UI Preview",
                section: "Sling Angles"
            ),
            verification: .init(
                status: .verified,
                reviewedBy: "UI Preview",
                reviewedOn: "2026-11-11"
            )
        ),

        ReferenceRecord(
            id: "REF-002",
            topic: "Pre-Use Sling Inspection",
            category: .inspection,
            tags: ["inspection", "sling inspection"],
            summary:
                "Slings should be inspected before use for visible damage or conditions that may affect safe operation.",
            aiContext:
                "Users should inspect sling condition before use and follow approved inspection requirements.",
            relatedCalculation: nil,
            source: .init(
                title: "Sample Rigging Reference",
                publisher: "RigAssist AI",
                edition: "UI Preview",
                section: "Inspection"
            ),
            verification: .init(
                status: .verified,
                reviewedBy: "UI Preview",
                reviewedOn: "2026-11-11"
            )
        )
    ]

    // MARK: - Record Lookup

    /// Returns a sample record matching the supplied identifier.
    ///
    /// Identifier matching is case-insensitive to support predictable
    /// behavior during interface development.
    func record(id: String) -> ReferenceRecord? {
        records.first {
            $0.id.caseInsensitiveCompare(id) == .orderedSame
        }
    }

    // MARK: - Reference Search

    /// Performs a lightweight search of the development-only records.
    ///
    /// The production search behavior remains the responsibility of
    /// LocalReferenceService. This implementation provides only the
    /// functionality required to exercise the Reference Library interface.
    func search(
        query: String,
        limit: Int
    ) -> [ReferenceRecord] {

        let normalizedQuery = query
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        // An empty query or invalid result limit should never return
        // development records automatically.
        guard !normalizedQuery.isEmpty, limit > 0 else {
            return []
        }

        let matches = records.filter { record in
            record.topic.lowercased().contains(normalizedQuery)
                || record.tags.contains {
                    $0.lowercased().contains(normalizedQuery)
                }
        }

        return Array(matches.prefix(limit))
    }

    // MARK: - AI Reference Search

    /// Provides sample reference records for AI interface development.
    ///
    /// The production LocalReferenceService is responsible for applying
    /// the stricter relevance and verification requirements used by the
    /// application's constrained AI workflow.
    ///
    /// This mock intentionally reuses its lightweight development search
    /// so it satisfies ReferenceServiceProtocol without duplicating or
    /// attempting to replace production retrieval logic.
    func searchForAI(
        query: String,
        limit: Int
    ) -> [ReferenceRecord] {
        search(
            query: query,
            limit: limit
        )
    }
}
