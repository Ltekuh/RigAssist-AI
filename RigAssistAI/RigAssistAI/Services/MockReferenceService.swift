//
//  MockReferenceService.swift
//  RigAssistAI
//
//  Created by Macauley Wain on 11/11/26.
//
//  UI-development implementation of ReferenceServiceProtocol.
//  This service exists only so the Reference Library interface can be
//  developed and tested before the production LocalReferenceService is
//  integrated.
//
//  IMPORTANT:
//  The records below are sample UI data only. They are not approved
//  rigging references and must never be treated as operational guidance.
//

import Foundation

struct MockReferenceService: ReferenceServiceProtocol {

    // MARK: - Dataset Disclaimer

    /// Development-only disclaimer displayed by the Reference Library.
    let disclaimer =
        "Prototype reference information only. Always verify lifting requirements against applicable standards, manufacturer instructions, and a qualified person."

    // MARK: - Sample UI Records

    /// Sample records used only to exercise Reference Library presentation,
    /// searching, source attribution, and empty-state behavior.
    ///
    /// These records intentionally identify their source as a UI preview so
    /// they cannot be confused with the approved production reference dataset.
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
    func record(id: String) -> ReferenceRecord? {
        records.first {
            $0.id.caseInsensitiveCompare(id) == .orderedSame
        }
    }

    // MARK: - Reference Search

    /// Performs a lightweight search of the development records.
    ///
    /// The production search behavior remains the responsibility of
    /// LocalReferenceService. This implementation only provides enough
    /// functionality to exercise the Reference Library interface.
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
}
