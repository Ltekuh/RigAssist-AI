//
//  CalculationEngineProtocol.swift
//  RigAssistAI
//
//  Defines the interface contract for the deterministic Calculation Engine.
//  The protocol specifies how other components request a calculation without
//  depending on the engine's internal implementation.
//

import Foundation

/// Contract implemented by the deterministic Calculation Engine.
///
/// SwiftUI depends on this protocol rather than a concrete calculation
/// implementation. This keeps the presentation layer separate from
/// safety-critical calculation logic and allows the engine to be tested
/// independently.
protocol CalculationEngineProtocol {

    /// Validates the supplied lift input and performs the supported
    /// deterministic rigging calculation.
    ///
    /// - Parameter input: Values collected by the calculator interface.
    /// - Returns: A successful CalculationResult or a defined
    ///   CalculationError when validation or calculation cannot proceed.
    func calculate(
        input: LiftInput
    ) -> Result<CalculationResult, CalculationError>
}
