//
//  ReferenceLibraryView.swift
//  RigAssistAI
//
//  Leonel's contribution: Search verified references offline and show provenance.
//

import SwiftUI

struct ReferenceLibraryView: View {
    let referenceService: any ReferenceServiceProtocol
    @State private var query = ""

    private var results: [ReferenceRecord] {
        referenceService.search(query: query, limit: 50)
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text(referenceService.disclaimer)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Important")
                }

                if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    ContentUnavailableView(
                        "Search verified references",
                        systemImage: "magnifyingglass",
                        description: Text(
                            "Search by topic or tag. Unverified records are hidden."
                        )
                    )
                    .listRowBackground(Color.clear)
                } else if results.isEmpty {
                    ContentUnavailableView(
                        "No verified references found",
                        systemImage: "books.vertical",
                        description: Text(
                            "Try another topic, or check the original source with a qualified person."
                        )
                    )
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(results) { record in
                        referenceRow(record)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Reference")
            .searchable(text: $query, prompt: "Topic or tag")
        }
    }

    private func referenceRow(_ record: ReferenceRecord) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(record.topic)
                .font(.headline)
            Text(record.summary)
                .font(.body)
            VStack(alignment: .leading, spacing: 2) {
                Text("Source: \(record.source.title)")
                Text("\(record.source.publisher), \(record.source.edition), \(record.source.section)")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}
