//
//  LocalReferenceService.swift
//  RigAssistAI
//
//  Leonel's contribution: Offline retrieval restricted to approved records.
//

import Foundation

/// Searches the immutable bundled dataset and never exposes unverified records.
struct LocalReferenceService: ReferenceServiceProtocol {
    let disclaimer: String
    private let verifiedRecords: [ReferenceRecord]

    init(dataset: ReferenceDataset) {
        disclaimer = dataset.disclaimer
        verifiedRecords = dataset.records.filter(\.isVerified)
    }

    init(bundle: Bundle = .main) throws {
        try self.init(dataset: ReferenceDataLoader.load(bundle: bundle))
    }

    func record(id: String) -> ReferenceRecord? {
        let requestedID = id.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !requestedID.isEmpty else { return nil }
        return verifiedRecords.first {
            $0.id.caseInsensitiveCompare(requestedID) == .orderedSame
        }
    }

    func search(query: String, limit: Int) -> [ReferenceRecord] {
        guard limit > 0 else { return [] }

        let normalizedQuery = Self.normalize(query)
        guard !normalizedQuery.isEmpty else { return [] }
        let queryWords = Set(normalizedQuery.split(separator: " ").map(String.init))

        let matches = verifiedRecords.compactMap { record -> (ReferenceRecord, Int)? in
            let topic = Self.normalize(record.topic)
            let tags = record.tags.map(Self.normalize)
            let topicWords = Set(topic.split(separator: " ").map(String.init))
            let tagWords = tags.flatMap { $0.split(separator: " ").map(String.init) }
            let matchedWords = queryWords.intersection(topicWords.union(tagWords))

            guard topic.contains(normalizedQuery)
                    || tags.contains(where: { $0.contains(normalizedQuery) })
                    || !matchedWords.isEmpty else {
                return nil
            }

            let score: Int
            if topic == normalizedQuery {
                score = 0
            } else if topic.contains(normalizedQuery) {
                score = 1
            } else if tags.contains(normalizedQuery) {
                score = 2
            } else if tags.contains(where: { $0.contains(normalizedQuery) }) {
                score = 3
            } else {
                score = 4 - min(matchedWords.count, 3)
            }
            return (record, score)
        }

        return matches
            .sorted {
                if $0.1 != $1.1 { return $0.1 < $1.1 }
                return $0.0.id < $1.0.id
            }
            .prefix(limit)
            .map(\.0)
    }

    private static func normalize(_ value: String) -> String {
        value
            .folding(options: [.caseInsensitive, .diacriticInsensitive],
                     locale: Locale(identifier: "en_US_POSIX"))
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
}
