import SwiftUI

/// Primary input screen for the RigAssist AI sling calculator.
///
/// This view is responsible only for collecting information from the user.
/// Safety-critical calculations are intentionally kept outside the UI and
/// will be handled by the deterministic Calculation Engine.
struct CalculatorView: View {

    // MARK: - User Input

    @State private var loadWeight = ""
    @State private var slingRatedCapacity = ""
    @State private var selectedConfiguration: SlingConfiguration = .verticalHitch
    @State private var slingAngle = ""

    var body: some View {
        NavigationStack {
            Form {

                // MARK: Load Information

                Section("Load Information") {
                    TextField("Load Weight (lb)", text: $loadWeight)
                        .keyboardType(.decimalPad)
                }

                // MARK: Sling Information

                Section("Sling Information") {
                    Picker("Configuration", selection: $selectedConfiguration) {
                        Text("Vertical Hitch")
                            .tag(SlingConfiguration.verticalHitch)

                        Text("Two-Leg Bridle")
                            .tag(SlingConfiguration.twoLegBridle)
                    }

                    TextField(
                        "Rated Capacity (lb)",
                        text: $slingRatedCapacity
                    )
                    .keyboardType(.decimalPad)

                    // Sling angle is only relevant to a two-leg bridle.
                    if selectedConfiguration == .twoLegBridle {
                        TextField(
                            "Sling Angle (30–90°)",
                            text: $slingAngle
                        )
                        .keyboardType(.decimalPad)
                    }
                }

                // MARK: Safety Information

                Section {
                    Text(
                        "RigAssist AI is an academic prototype. Calculator results must be verified by a qualified person before use in lift planning."
                    )
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                }

                // MARK: Calculate

                Section {
                    Button("Calculate") {
                        // Calculation behavior will be connected to the
                        // deterministic Calculation Engine separately.
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("Rigging Calculator")
        }
    }
}

#Preview {
    CalculatorView()
}
