//
//  CalculationResult.swift
//  RigAssistAI
//
//  Defines the output contract returned by the deterministic
//  Calculation Engine after a successful rigging calculation.
//

import Foundation

/// Represents the result of a successful calculation.
///
/// The Calculation Engine produces these values after validating a LiftInput.
/// SwiftUI may display these results, but it must not independently recalculate
/// or modify safety-critical values.
struct CalculationResult: Codable, Equatable {

    /// Angle multiplier used by the Calculation Engine.
    ///
    /// A vertical hitch uses a multiplier of 1.0. For supported bridle
    /// configurations, the engine determines the appropriate multiplier
    /// from the validated sling angle.
    let angleMultiplier: Double

    /// Portion of the total load assigned to each sling leg, in pounds.
    let loadPerLegLb: Double

    /// Calculated tension applied to each sling leg, in pounds.
    let tensionPerLegLb: Double

    /// Ratio of calculated sling tension to the sling's rated capacity.
    ///
    /// Example: 0.75 represents 75 percent utilization.
    let utilization: Double

    /// Indicates whether the calculated tension remains within the
    /// provided sling rated capacity.
    let withinRatedCapacity: Bool

    /// Non-fatal messages that should be presented with the result.
    ///
    /// Warnings provide additional context but do not replace the
    /// application's safety disclaimer or qualified human verification.
    let warnings: [String]
}
