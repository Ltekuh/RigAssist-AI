//
//  CalculatorResultsView.swift
//  RigAssistAI
//
//  Displays validated results returned by the deterministic
//  Calculation Engine. This view does not perform rigging calculations.
//

import SwiftUI

struct CalculatorResultsView: View {

    // MARK: - Input Data

    /// The validated input originally submitted to the Calculation Engine.
    /// This is displayed only as a summary for the user.
    let input: LiftInput

    /// The completed result returned by the Calculation Engine.
    /// Safety-critical values displayed by this view come directly from
    /// this result rather than being recalculated in the UI.
    let result: CalculationResult

    var body: some View {
        ScrollView {
            VStack(spacing: RigAssistTheme.sectionSpacing) {

                // MARK: - Header

                headerCard

                // MARK: - Capacity Status

                capacityStatusCard

                // MARK: - Calculation Results

                resultsCard

                // MARK: - Input Summary

                inputSummaryCard

                // MARK: - Warnings

                if !result.warnings.isEmpty {
                    warningsCard
                }

                // MARK: - Safety Notice

                safetyNoticeCard
            }
            .padding(.horizontal, RigAssistTheme.screenPadding)
            .padding(.vertical, 20)
        }
        .background(RigAssistTheme.background)
        .navigationTitle("Calculation Results")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Header Card

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("RigAssist AI")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(RigAssistTheme.safetyOrange)

            Text("Calculation Results")
                .font(.title.bold())
                .foregroundStyle(.white)

            Text("Deterministic calculation results based on your validated inputs.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(RigAssistTheme.cardPadding)
        .background(
            RigAssistTheme.navy,
            in: RoundedRectangle(
                cornerRadius: RigAssistTheme.cardCornerRadius
            )
        )
    }

    // MARK: - Capacity Status Card

    private var capacityStatusCard: some View {
        VStack(spacing: 12) {
            Image(
                systemName: result.withinRatedCapacity
                    ? "checkmark.circle.fill"
                    : "exclamationmark.triangle.fill"
            )
            .font(.system(size: 38))
            .foregroundStyle(
                result.withinRatedCapacity
                    ? .green
                    : RigAssistTheme.warning
            )

            Text(
                result.withinRatedCapacity
                    ? "Within Rated Capacity"
                    : "Exceeds Rated Capacity"
            )
            .font(.title3.bold())
            .foregroundStyle(RigAssistTheme.primaryText)

            Text("\(formattedPercent(result.utilization)) capacity utilization")
                .font(.subheadline)
                .foregroundStyle(RigAssistTheme.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(RigAssistTheme.cardPadding)
        .background(
            RigAssistTheme.cardBackground,
            in: RoundedRectangle(
                cornerRadius: RigAssistTheme.cardCornerRadius
            )
        )
    }

    // MARK: - Results Card

    private var resultsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Calculated Values", systemImage: "function")
                .font(.headline)
                .foregroundStyle(RigAssistTheme.primaryText)

            resultRow(
                title: "Load Per Leg",
                value: "\(formattedPounds(result.loadPerLegLb)) lb"
            )

            Divider()

            resultRow(
                title: "Tension Per Leg",
                value: "\(formattedPounds(result.tensionPerLegLb)) lb"
            )

            Divider()

            resultRow(
                title: "Angle Multiplier",
                value: formattedMultiplier(result.angleMultiplier)
            )

            Divider()

            resultRow(
                title: "Capacity Utilization",
                value: formattedPercent(result.utilization)
            )
        }
        .padding(RigAssistTheme.cardPadding)
        .background(
            RigAssistTheme.cardBackground,
            in: RoundedRectangle(
                cornerRadius: RigAssistTheme.cardCornerRadius
            )
        )
    }

    // MARK: - Input Summary Card

    private var inputSummaryCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Input Summary", systemImage: "list.clipboard")
                .font(.headline)
                .foregroundStyle(RigAssistTheme.primaryText)

            resultRow(
                title: "Load Weight",
                value: "\(formattedPounds(input.loadWeightLb)) lb"
            )

            Divider()

            resultRow(
                title: "Configuration",
                value: configurationName
            )

            if let angle = input.angleDegrees {
                Divider()

                resultRow(
                    title: "Sling Angle",
                    value: "\(formattedAngle(angle))°"
                )
            }

            Divider()

            resultRow(
                title: "Rated Capacity",
                value: "\(formattedPounds(input.slingRatedCapacityLb)) lb"
            )
        }
        .padding(RigAssistTheme.cardPadding)
        .background(
            RigAssistTheme.cardBackground,
            in: RoundedRectangle(
                cornerRadius: RigAssistTheme.cardCornerRadius
            )
        )
    }

    // MARK: - Warnings Card

    private var warningsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Warnings", systemImage: "exclamationmark.triangle.fill")
                .font(.headline)
                .foregroundStyle(RigAssistTheme.warning)

            ForEach(result.warnings, id: \.self) { warning in
                Text("• \(warning)")
                    .font(.subheadline)
                    .foregroundStyle(RigAssistTheme.primaryText)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(RigAssistTheme.cardPadding)
        .background(
            RigAssistTheme.cardBackground,
            in: RoundedRectangle(
                cornerRadius: RigAssistTheme.cardCornerRadius
            )
        )
    }

    // MARK: - Safety Notice

    private var safetyNoticeCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "shield.lefthalf.filled")
                .foregroundStyle(RigAssistTheme.safetyOrange)

            VStack(alignment: .leading, spacing: 4) {
                Text("Safety Notice")
                    .font(.subheadline.bold())
                    .foregroundStyle(RigAssistTheme.primaryText)

                Text(
                    "RigAssist AI is an academic prototype. "
                    + "Calculation results must be verified by a qualified person "
                    + "before use in lift planning or field operations."
                )
                .font(.footnote)
                .foregroundStyle(RigAssistTheme.secondaryText)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(RigAssistTheme.cardPadding)
        .background(
            RigAssistTheme.cardBackground,
            in: RoundedRectangle(
                cornerRadius: RigAssistTheme.cardCornerRadius
            )
        )
    }

    // MARK: - Reusable Result Row

    private func resultRow(title: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .foregroundStyle(RigAssistTheme.secondaryText)

            Spacer()

            Text(value)
                .fontWeight(.semibold)
                .foregroundStyle(RigAssistTheme.primaryText)
                .multilineTextAlignment(.trailing)
        }
    }

    // MARK: - Display Formatting

    /// Formats pound values for display only.
    /// This does not alter or recalculate the engine result.
    private func formattedPounds(_ value: Double) -> String {
        value.formatted(
            .number
                .grouping(.automatic)
                .precision(.fractionLength(0...1))
        )
    }

    /// Converts the utilization ratio returned by the engine into
    /// a percentage for display only.
    private func formattedPercent(_ value: Double) -> String {
        value.formatted(
            .percent
                .precision(.fractionLength(0...1))
        )
    }

    private func formattedMultiplier(_ value: Double) -> String {
        value.formatted(
            .number.precision(.fractionLength(2))
        )
    }

    private func formattedAngle(_ value: Double) -> String {
        value.formatted(
            .number.precision(.fractionLength(0...1))
        )
    }

    /// Provides a human-readable label for the supported configuration.
    private var configurationName: String {
        switch input.configuration {
        case .verticalHitch:
            return "Vertical Hitch"

        case .twoLegBridle:
            return "Two-Leg Bridle"
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        CalculatorResultsView(
            input: LiftInput(
                loadWeightLb: 5_000,
                configuration: .twoLegBridle,
                angleDegrees: 60,
                slingRatedCapacityLb: 4_000
            ),
            result: CalculationResult(
                angleMultiplier: 1.15,
                loadPerLegLb: 2_500,
                tensionPerLegLb: 2_875,
                utilization: 0.71875,
                withinRatedCapacity: true,
                warnings: []
            )
        )
    }
}
