import SwiftUI

/// Primary input screen for the RigAssist AI sling calculator.
///
/// This view collects and validates user-entered values before they are
/// submitted to the deterministic Calculation Engine. Safety-critical
/// calculations remain outside the UI.
struct CalculatorView: View {

    // MARK: - User Input

    @State private var loadWeight = ""
    @State private var slingRatedCapacity = ""
    @State private var selectedConfiguration: SlingConfiguration = .verticalHitch
    @State private var slingAngle = ""

    // MARK: - Validation State

    @State private var validationMessage: String?

    // MARK: - Calculation State

    /// Temporary engine used while the production deterministic
    /// Calculation Engine is being implemented.
    ///
    /// The UI communicates through CalculationEngineProtocol so the
    /// production engine can replace the mock without redesigning the view.
    private let calculationEngine: any CalculationEngineProtocol =
        MockCalculationEngine()

    /// Stores the validated input used for the completed calculation.
    @State private var completedInput: LiftInput?

    /// Stores the result returned by the Calculation Engine.
    @State private var completedResult: CalculationResult?

    /// Controls navigation to the calculation results screen.
    @State private var showResults = false

    var body: some View {
        NavigationStack {
            ZStack {
                RigAssistTheme.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: RigAssistTheme.sectionSpacing) {

                        // MARK: Header

                        header

                        // MARK: Load Information

                        inputCard(
                            title: "LOAD",
                            systemImage: "scalemass.fill"
                        ) {
                            VStack(alignment: .leading, spacing: 8) {
                                fieldLabel("Load Weight")

                                HStack {
                                    TextField(
                                        "Enter weight",
                                        text: $loadWeight
                                    )
                                    .keyboardType(.numberPad)
                                    .onChange(of: loadWeight) { _, newValue in
                                        loadWeight = formatWholeNumber(newValue)
                                    }

                                    Text("lb")
                                        .foregroundStyle(
                                            RigAssistTheme.secondaryText
                                        )
                                }
                                .inputFieldStyle()
                            }
                        }

                        // MARK: Sling Setup

                        inputCard(
                            title: "SLING SETUP",
                            systemImage: "link"
                        ) {
                            VStack(alignment: .leading, spacing: 16) {

                                fieldLabel("Configuration")

                                Picker(
                                    "Configuration",
                                    selection: $selectedConfiguration
                                ) {
                                    Text("Vertical Hitch")
                                        .tag(SlingConfiguration.verticalHitch)

                                    Text("Two-Leg Bridle")
                                        .tag(SlingConfiguration.twoLegBridle)
                                }
                                .pickerStyle(.menu)
                                .tint(RigAssistTheme.navy)
                                .frame(
                                    maxWidth: .infinity,
                                    alignment: .leading
                                )
                                .padding(.horizontal, 14)
                                .frame(height: 50)
                                .background(
                                    RigAssistTheme.background,
                                    in: RoundedRectangle(
                                        cornerRadius:
                                            RigAssistTheme.controlCornerRadius
                                    )
                                )

                                fieldLabel("Rated Capacity")

                                HStack {
                                    TextField(
                                        "Enter capacity",
                                        text: $slingRatedCapacity
                                    )
                                    .keyboardType(.numberPad)
                                    .onChange(
                                        of: slingRatedCapacity
                                    ) { _, newValue in
                                        slingRatedCapacity =
                                            formatWholeNumber(newValue)
                                    }

                                    Text("lb")
                                        .foregroundStyle(
                                            RigAssistTheme.secondaryText
                                        )
                                }
                                .inputFieldStyle()

                                if selectedConfiguration == .twoLegBridle {
                                    fieldLabel("Sling Angle")

                                    HStack {
                                        TextField(
                                            "30–90",
                                            text: $slingAngle
                                        )
                                        .keyboardType(.decimalPad)

                                        Text("°")
                                            .foregroundStyle(
                                                RigAssistTheme.secondaryText
                                            )
                                    }
                                    .inputFieldStyle()
                                    .transition(
                                        .opacity.combined(
                                            with: .move(edge: .top)
                                        )
                                    )
                                }
                            }
                        }

                        // MARK: Validation

                        if let validationMessage {
                            validationCard(validationMessage)
                        }

                        // MARK: Calculate

                        Button {
                            validateInput()
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "function")

                                Text("CALCULATE")
                                    .fontWeight(.bold)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .foregroundStyle(.white)
                            .background(
                                RigAssistTheme.safetyOrange,
                                in: RoundedRectangle(
                                    cornerRadius:
                                        RigAssistTheme.controlCornerRadius
                                )
                            )
                        }

                        // MARK: Safety Notice

                        safetyNotice
                    }
                    .padding(RigAssistTheme.screenPadding)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .animation(
                .easeInOut(duration: 0.2),
                value: selectedConfiguration
            )
            .onChange(of: selectedConfiguration) { _, newValue in

                // Vertical hitches do not require a sling angle.
                // Clear any previously entered angle when switching modes.
                if newValue == .verticalHitch {
                    slingAngle = ""
                }

                validationMessage = nil
            }

            // Navigation occurs only after the Calculation Engine
            // successfully returns a result.
            .navigationDestination(isPresented: $showResults) {
                if let input = completedInput,
                   let result = completedResult {
                    CalculatorResultsView(
                        input: input,
                        result: result
                    )
                }
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                Image(systemName: "link.circle.fill")
                    .font(.title2)
                    .foregroundStyle(RigAssistTheme.safetyOrange)

                Text("RIGASSIST AI")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .tracking(1.5)
                    .foregroundStyle(RigAssistTheme.safetyOrange)
            }

            Text("Rigging Calculator")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundStyle(.white)

            Text("Enter the load and sling information below.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.75))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(22)
        .background(
            RigAssistTheme.navy,
            in: RoundedRectangle(
                cornerRadius: RigAssistTheme.cardCornerRadius
            )
        )
    }

    // MARK: - Reusable UI Components

    private func inputCard<Content: View>(
        title: String,
        systemImage: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .foregroundStyle(RigAssistTheme.safetyOrange)

                Text(title)
                    .font(.caption)
                    .fontWeight(.bold)
                    .tracking(1.2)
                    .foregroundStyle(RigAssistTheme.navy)
            }

            content()
        }
        .padding(RigAssistTheme.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RigAssistTheme.cardBackground,
            in: RoundedRectangle(
                cornerRadius: RigAssistTheme.cardCornerRadius
            )
        )
        .shadow(
            color: .black.opacity(0.05),
            radius: 8,
            x: 0,
            y: 3
        )
    }

    private func fieldLabel(_ title: String) -> some View {
        Text(title)
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundStyle(RigAssistTheme.primaryText)
    }

    private func validationCard(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(RigAssistTheme.warning)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(RigAssistTheme.primaryText)

            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RigAssistTheme.warning.opacity(0.08),
            in: RoundedRectangle(
                cornerRadius: RigAssistTheme.controlCornerRadius
            )
        )
    }

    private var safetyNotice: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "shield.checkered")
                .foregroundStyle(RigAssistTheme.safetyOrange)

            VStack(alignment: .leading, spacing: 4) {
                Text("SAFETY NOTICE")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(RigAssistTheme.navy)

                Text(
                    "RigAssist AI is an academic prototype. "
                    + "Calculator results must be verified by a qualified "
                    + "person before use in lift planning."
                )
                .font(.footnote)
                .foregroundStyle(RigAssistTheme.secondaryText)
            }

            Spacer()
        }
        .padding(RigAssistTheme.cardPadding)
        .background(
            RigAssistTheme.cardBackground,
            in: RoundedRectangle(
                cornerRadius: RigAssistTheme.cardCornerRadius
            )
        )
    }

    // MARK: - Number Formatting

    /// Formats whole-number weight values with thousands separators.
    ///
    /// Examples:
    /// 1000 -> 1,000
    /// 12500 -> 12,500
    /// 100000 -> 100,000
    private func formatWholeNumber(_ value: String) -> String {

        // Remove existing commas and any non-numeric characters.
        let digits = value
            .replacingOccurrences(of: ",", with: "")
            .filter { $0.isNumber }

        guard !digits.isEmpty,
              let number = Int(digits) else {
            return digits
        }

        return number.formatted(
            .number.grouping(.automatic)
        )
    }

    /// Removes display formatting before converting a weight value
    /// into a numeric value for the shared LiftInput model.
    private func numericValue(
        from formattedValue: String
    ) -> Double? {
        let unformattedValue = formattedValue
            .replacingOccurrences(of: ",", with: "")

        return Double(unformattedValue)
    }

    // MARK: - Input Validation

    private func validateInput() {
        validationMessage = nil

        // Load weight must be a finite value greater than zero.
        guard let weight = numericValue(from: loadWeight),
              weight.isFinite,
              weight > 0 else {
            validationMessage =
                "Enter a valid load weight greater than 0 lb."
            return
        }

        // Rated sling capacity must be a finite value greater than zero.
        guard let capacity = numericValue(
            from: slingRatedCapacity
        ),
        capacity.isFinite,
        capacity > 0 else {
            validationMessage =
                "Enter a valid sling rated capacity greater than 0 lb."
            return
        }

        var angle: Double?

        // A two-leg bridle requires a supported sling angle.
        if selectedConfiguration == .twoLegBridle {
            guard let enteredAngle = Double(slingAngle),
                  enteredAngle.isFinite else {
                validationMessage =
                    "Enter a sling angle for the two-leg bridle."
                return
            }

            guard (30...90).contains(enteredAngle) else {
                validationMessage =
                    "Sling angle must be between 30° and 90°."
                return
            }

            angle = enteredAngle
        }

        // Construct LiftInput only after UI validation succeeds.
        let input = LiftInput(
            loadWeightLb: weight,
            configuration: selectedConfiguration,
            angleDegrees: angle,
            slingRatedCapacityLb: capacity
        )

        submitValidatedInput(input)
    }

    // MARK: - Calculation Handoff

    private func submitValidatedInput(
        _ input: LiftInput
    ) {
        validationMessage = nil

        // Pass validated input through the Calculation Engine contract.
        // SwiftUI does not perform or reproduce safety-critical math.
        let calculation =
            calculationEngine.calculate(input: input)

        switch calculation {

        case .success(let result):

            // Store the exact validated input and engine-produced result.
            completedInput = input
            completedResult = result

            // Navigate only after both values have been stored.
            showResults = true

        case .failure(let error):

            // Calculation failures remain blocking and are presented
            // directly to the user rather than delegated to AI.
            validationMessage = error.localizedDescription
        }
    }
}

// MARK: - Shared Input Field Styling

private extension View {
    func inputFieldStyle() -> some View {
        self
            .padding(.horizontal, 14)
            .frame(height: 50)
            .background(
                RigAssistTheme.background,
                in: RoundedRectangle(
                    cornerRadius:
                        RigAssistTheme.controlCornerRadius
                )
            )
    }
}

#Preview {
    CalculatorView()
}
