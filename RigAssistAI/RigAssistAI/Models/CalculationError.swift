//
//  CalculationError.swift
//  RigAssistAI
//
//  Defines validation and calculation errors that may be returned
//  by the deterministic Calculation Engine.
//

import Foundation

/// Errors that may occur while validating or processing a LiftInput.
///
/// Defining these errors in a shared contract allows the Calculation Engine
/// and SwiftUI interface to communicate failures without relying on
/// inconsistent error strings.
enum CalculationError: Error, Equatable {

    /// A required numeric value is not finite or is less than
    /// or equal to zero.
    case invalidNumber

    /// A sling angle is required for the selected configuration
    /// but was not provided.
    case missingAngle

    /// An angle was supplied for a configuration that does not use one.
    case unexpectedAngle

    /// The supplied sling angle falls outside the supported range
    /// of 30 through 90 degrees.
    case angleOutOfSupportedRange

    /// The requested sling configuration is not supported by the
    /// current calculator implementation.
    case unsupportedConfiguration
}

/// Provides consistent user-facing messages for calculation errors.
///
/// These messages may be displayed by SwiftUI, while the actual validation
/// rules remain the responsibility of the Calculation Engine.
extension CalculationError {

    var userMessage: String {
        switch self {
        case .invalidNumber:
            return "Enter valid values greater than zero."

        case .missingAngle:
            return "A sling angle is required for a two-leg bridle."

        case .unexpectedAngle:
            return "A sling angle is not used for a vertical hitch."

        case .angleOutOfSupportedRange:
            return "Enter a sling angle between 30 and 90 degrees."

        case .unsupportedConfiguration:
            return "The selected sling configuration is not supported."
        }
    }
}
