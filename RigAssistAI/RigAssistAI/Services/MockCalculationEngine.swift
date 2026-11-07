//
//  MockCalculationEngine.swift
//  RigAssistAI
//
//  Development-only implementation of CalculationEngineProtocol.
//  Allows the calculator interface and results screen to be tested
//  before the production Calculation Engine is integrated.
//

import Foundation

/// Temporary Calculation Engine used only for interface development.
///
/// IMPORTANT:
/// This mock does not perform rigging calculations and must not be
/// treated as an approved source of safety-critical calculation results.
///
/// The production Calculation Engine will replace this implementation
/// once the deterministic calculation logic is integrated.
struct MockCalculationEngine: CalculationEngineProtocol {

    func calculate(
        input: LiftInput
    ) -> Result<CalculationResult, CalculationError> {

        // Return predetermined demonstration values so the SwiftUI
        // calculation workflow can be developed independently from
        // the production Calculation Engine.
        let mockResult = CalculationResult(
            angleMultiplier: 1.15,
            loadPerLegLb: 2_500,
            tensionPerLegLb: 2_875,
            utilization: 0.71875,
            withinRatedCapacity: true,
            warnings: [
                "Development preview only. Results are not approved for field use."
            ]
        )

        return .success(mockResult)
    }
}
