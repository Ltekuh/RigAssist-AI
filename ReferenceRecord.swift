import Foundation

// RA-105: Swift model for the bundled, read-only reference dataset.
// Mirrors docs/reference-data.md. Keep the two in sync.

struct ReferenceDataset: Codable {
    let schemaVersion: String
    let datasetVersion: String
    let disclaimer: String
    let records: [ReferenceRecord]
}

struct ReferenceRecord: Codable, Identifiable, Hashable {
    let id: String
    let topic: String
    let category: Category
    let tags: [String]
    let summary: String
    let aiContext: String
    let relatedCalculation: String?
    let source: Source
    let verification: Verification

    enum Category: String, Codable, CaseIterable {
        case loadAngle = "load_angle"
        case slingConfiguration = "sling_configuration"
        case capacity
        case inspection
        case liftPlanning = "lift_planning"
        case appScope = "app_scope"
    }

    struct Source: Codable, Hashable {
        let title: String
        let publisher: String
        let edition: String
        let section: String
    }

    struct Verification: Codable, Hashable {
        let status: Status
        let reviewedBy: String?
        let reviewedOn: String?

        enum Status: String, Codable {
            case unverified
            case verified
        }
    }

    var isVerified: Bool { verification.status == .verified }
}

enum ReferenceDataError: Error, LocalizedError {
    case fileNotFound
    case decodingFailed(String)

    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "The reference data file is missing from the app bundle."
        case .decodingFailed(let detail):
            return "The reference data could not be read: \(detail)"
        }
    }
}

enum ReferenceDataLoader {
    /// Loads the bundled dataset. Fails loudly so a malformed file is caught immediately.
    static func load(resource: String = "reference_records",
                     bundle: Bundle = .main) throws -> ReferenceDataset {
        guard let url = bundle.url(forResource: resource, withExtension: "json") else {
            throw ReferenceDataError.fileNotFound
        }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(ReferenceDataset.self, from: data)
        } catch {
            throw ReferenceDataError.decodingFailed(String(describing: error))
        }
    }
}
