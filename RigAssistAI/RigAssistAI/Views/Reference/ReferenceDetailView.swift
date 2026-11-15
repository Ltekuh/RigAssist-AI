//
//  ReferenceDetailView.swift
//  RigAssistAI
//
//  Created by Macauley Wain on 11/11/26.
//
//  Presents the complete user-facing details for a verified reference
//  selected from the Reference Library.
//
//  This view displays information supplied by the Reference Service.
//  It does not perform calculations, modify reference content, or
//  independently determine whether a reference is technically approved.
//

import SwiftUI

struct ReferenceDetailView: View {

    // MARK: - Reference Data

    /// Verified reference record selected from the Reference Library.
    let record: ReferenceRecord

    /// Dataset-level safety disclaimer supplied by the active
    /// Reference Service.
    let disclaimer: String

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                headerSection

                overviewSection

                sourceSection

                if let relatedCalculation = record.relatedCalculation,
                   !relatedCalculation.isEmpty {
                    relatedCalculationSection(
                        relatedCalculation
                    )
                }

                safetySection
            }
            .padding()
        }
        .background(
            RigAssistTheme.background
                .ignoresSafeArea()
        )
        .navigationTitle("Reference Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Header

private extension ReferenceDetailView {

    var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {

            Text(record.topic)
                .font(.title2)
                .fontWeight(.bold)

            HStack(spacing: 8) {
                Image(systemName: "checkmark.shield.fill")

                Text("Verified Reference")
                    .fontWeight(.semibold)
            }
            .font(.subheadline)
            .foregroundStyle(.green)
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
    }
}

// MARK: - Overview

private extension ReferenceDetailView {

    var overviewSection: some View {
        VStack(alignment: .leading, spacing: 10) {

            sectionTitle("Overview")

            Text(record.summary)
                .font(.body)
                .foregroundStyle(.primary)
                .fixedSize(
                    horizontal: false,
                    vertical: true
                )
        }
        .referenceDetailCard()
    }
}

// MARK: - Source Information

private extension ReferenceDetailView {

    var sourceSection: some View {
        VStack(alignment: .leading, spacing: 14) {

            sectionTitle("Source")

            sourceRow(
                label: "Title",
                value: record.source.title
            )

            Divider()

            sourceRow(
                label: "Publisher",
                value: record.source.publisher
            )

            Divider()

            sourceRow(
                label: "Edition",
                value: record.source.edition
            )

            Divider()

            sourceRow(
                label: "Section",
                value: record.source.section
            )
        }
        .referenceDetailCard()
    }

    func sourceRow(
        label: String,
        value: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {

            Text(label.uppercased())
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.subheadline)
                .foregroundStyle(.primary)
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
    }
}

// MARK: - Related Calculation

private extension ReferenceDetailView {

    /// Displays the relationship between this reference and a calculator
    /// function when one is supplied by the approved dataset.
    ///
    /// This is intentionally informational for now. Navigation to a
    /// calculator function will be added only after the shared calculation
    /// identifiers are finalized during integration.
    func relatedCalculationSection(
        _ calculation: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {

            sectionTitle("Related Tool")

            HStack(spacing: 12) {
                Image(systemName: "function")
                    .font(.title3)

                VStack(alignment: .leading, spacing: 3) {
                    Text("Calculator")
                        .font(.headline)

                    Text(calculation)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
        }
        .referenceDetailCard()
    }
}

// MARK: - Safety Notice

private extension ReferenceDetailView {

    var safetySection: some View {
        VStack(alignment: .leading, spacing: 10) {

            HStack(spacing: 8) {
                Image(
                    systemName:
                        "exclamationmark.triangle.fill"
                )
                .foregroundStyle(.orange)

                Text("Safety Notice")
                    .font(.headline)
            }

            Text(disclaimer)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(
                    horizontal: false,
                    vertical: true
                )
        }
        .referenceDetailCard()
    }
}

// MARK: - Shared Components

private extension ReferenceDetailView {

    func sectionTitle(
        _ title: String
    ) -> some View {
        Text(title)
            .font(.headline)
            .fontWeight(.semibold)
    }
}

// MARK: - Detail Card Styling

private extension View {

    /// Applies the same card treatment used throughout the
    /// RigAssist AI interface.
    func referenceDetailCard() -> some View {
        self
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
