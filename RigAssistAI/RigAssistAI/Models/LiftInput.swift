//
//  LiftInput.swift
//  RigAssistAI
//
//  Defines the validated input contract used by the deterministic
//  Calculation Engine. The AI Service must never perform or modify
//  these safety-critical calculations.
//

import Foundation

/// Describes the sling configuration supported by the calculator.
///
/// Keeping the supported configurations in an enum prevents other
/// components from passing arbitrary string values to the Calculation Engine.
enum SlingConfiguration: String, Codable, CaseIterable {
    case verticalHitch
    case twoLegBridle
}

/// Contains the values required by the Calculation Engine.
///
/// This model acts as the contract between the SwiftUI calculator interface
/// and the deterministic Calculation Engine. The UI collects these values,
/// but the Calculation Engine is responsible for validating them before
/// performing a calculation.
struct LiftInput: Codable, Equatable {

    /// Total weight of the load in pounds.
    /// Expected value: finite and greater than zero.
    let loadWeightLb: Double

    /// Sling configuration selected by the user.
    let configuration: SlingConfiguration

    /// Sling angle measured in degrees.
    ///
    /// Required for a two-leg bridle and must be between 30 and 90 degrees.
    /// A vertical hitch does not require an angle, so this value is optional.
    let angleDegrees: Double?

    /// Rated capacity of the selected sling in pounds.
    /// Expected value: finite and greater than zero.
    let slingRatedCapacityLb: Double
}
