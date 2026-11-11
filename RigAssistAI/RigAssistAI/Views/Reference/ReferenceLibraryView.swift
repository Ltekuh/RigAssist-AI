//
//  ReferenceLibraryView.swift
//  RigAssistAI
//
//  Created by Macauley Wain on 11/11/26.
//
//  Provides the user-facing interface for searching verified rigging
//  reference information supplied through ReferenceServiceProtocol.
//
//  This view does not determine whether reference information is approved.
//  Verification and filtering remain the responsibility of the Reference
//  Service. The interface only presents records returned by that service.
//

import SwiftUI

struct ReferenceLibraryView: View {

    // MARK: - Dependencies

    /// Reference Service used to retrieve verified reference information.
    ///
    /// During interface development this may be MockReferenceService.
    /// The production LocalReferenceService can later be injected without
    /// requiring the interface to change.
    let referenceService: any ReferenceServiceProtocol

    // MARK: - State

    /// Current search text entered by the user.
    @State private var searchText = ""

    // MARK: - Search Results

    /// Records returned by the active Reference Service for the
    /// user's current search query.
    private var searchResults: [ReferenceRecord] {
        referenceService.search(
            query: searchText,
            limit: 50
        )
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                RigAssistTheme.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {

                        headerSection

                        disclaimerSection

                        searchSection

                        resultsSection
                    }
                    .padding()
                }
            }
            .navigationTitle("Reference Library")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Header and Search

private extension ReferenceLibraryView {

    var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {

            Text("Verified Rigging References")
                .font(.title2)
                .fontWeight(.bold)

            Text(
                "Search approved reference information and review the source used for each entry."
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
    }

    var disclaimerSection: some View {
        HStack(alignment: .top, spacing: 12) {

            Image(
                systemName:
                    "exclamationmark.triangle.fill"
            )
            .foregroundStyle(.orange)

            Text(referenceService.disclaimer)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(
                    horizontal: false,
                    vertical: true
                )
        }
        .padding()
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .background(
            RoundedRectangle(
                cornerRadius:
                    RigAssistTheme.cardCornerRadius
            )
            .fill(
                RigAssistTheme.cardBackground
            )
        )
    }

    var searchSection: some View {
        HStack(spacing: 10) {

            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField(
                "Search references",
                text: $searchText
            )
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(
                        systemName:
                            "xmark.circle.fill"
                    )
                    .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, 14)
        .frame(height: 50)
        .background(
            RoundedRectangle(
                cornerRadius:
                    RigAssistTheme.controlCornerRadius
            )
            .fill(
                RigAssistTheme.cardBackground
            )
        )
    }
}

// MARK: - Search Results

private extension ReferenceLibraryView {

    @ViewBuilder
    var resultsSection: some View {

        let trimmedSearch = searchText.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        if trimmedSearch.isEmpty {

            emptySearchState

        } else if searchResults.isEmpty {

            noResultsState

        } else {

            LazyVStack(spacing: 14) {
                ForEach(searchResults) { record in

                    // Each result navigates to the complete reference
                    // information while preserving the same verified
                    // record returned by the Reference Service.
                    NavigationLink {
                        ReferenceDetailView(
                            record: record,
                            disclaimer:
                                referenceService.disclaimer
                        )
                    } label: {
                        referenceCard(
                            for: record
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// MARK: - Empty States

private extension ReferenceLibraryView {

    var emptySearchState: some View {
        VStack(spacing: 12) {

            Image(systemName: "books.vertical")
                .font(.system(size: 34))
                .foregroundStyle(.secondary)

            Text("Search the Reference Library")
                .font(.headline)

            Text(
                "Enter a rigging topic above to search verified reference information."
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
        }
        .padding(.vertical, 36)
        .frame(maxWidth: .infinity)
    }

    var noResultsState: some View {
        VStack(spacing: 12) {

            Image(systemName: "checkmark.shield")
                .font(.system(size: 34))
                .foregroundStyle(.secondary)

            Text("No Verified References Found")
                .font(.headline)

            Text(
                "No approved reference information is currently available for this search."
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
        }
        .padding(.vertical, 36)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Reference Result Card

private extension ReferenceLibraryView {

    /// Compact presentation of a Reference Service result.
    ///
    /// Detailed source metadata is presented by ReferenceDetailView so
    /// search results remain easy to scan when the production dataset
    /// contains multiple matching records.
    func referenceCard(
        for record: ReferenceRecord
    ) -> some View {

        VStack(alignment: .leading, spacing: 12) {

            // MARK: Record Header

            HStack(alignment: .top) {

                VStack(
                    alignment: .leading,
                    spacing: 6
                ) {

                    Text(record.topic)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    HStack(spacing: 5) {
                        Image(
                            systemName:
                                "checkmark.shield.fill"
                        )

                        Text("Verified Reference")
                    }
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.green)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
            }

            // MARK: Summary

            Text(record.summary)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(
                    horizontal: false,
                    vertical: true
                )

            Divider()

            // MARK: Source Preview

            HStack(spacing: 8) {

                Image(systemName: "doc.text")
                    .foregroundStyle(.secondary)

                VStack(
                    alignment: .leading,
                    spacing: 2
                ) {

                    Text("Source")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)

                    Text(record.source.title)
                        .font(.caption)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                }

                Spacer()

                Text("View Details")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .background(
            RoundedRectangle(
                cornerRadius:
                    RigAssistTheme.cardCornerRadius
            )
            .fill(
                RigAssistTheme.cardBackground
            )
        )
    }
}
