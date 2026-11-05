//
//  AIServiceProtocol.swift
//  RigAssistAI
//
//  Defines the interface contract between the RigAssist AI user interface
//  and the application's constrained AI assistant.
//

import Foundation

/// Represents the result returned by the AI Service.
///
/// The response contains either an approved AI-generated explanation or
/// a controlled fallback message. Source records allow the interface to
/// show which approved reference information supported the response.
struct AssistantResponse: Equatable {
    
    /// Text displayed to the user.
    let answer: String
    
    /// Indicates whether the response is a controlled fallback rather
    /// than an AI-generated explanation.
    let isFallback: Bool
    
    /// Approved reference records associated with the response.
    let sources: [ReferenceRecord]
    
    /// Optional explanation describing why a fallback occurred.
    let fallbackReason: String?
}

/// Defines the operations available to components that use the
/// constrained RigAssist AI assistant.
///
/// AI assistance remains separate from the deterministic Calculation
/// Engine and must never perform or override safety-critical calculations.
protocol AIServiceProtocol {
    
    /// Processes a validated natural-language question and returns either
    /// a supported explanation or a controlled fallback response.
    ///
    /// Implementations are responsible for retrieving approved reference
    /// context, communicating with the external AI provider when available,
    /// validating the returned response, and applying fallback behavior.
    ///
    /// - Parameter question: Natural-language question entered by the user.
    /// - Returns: An AssistantResponse containing the answer, approved
    ///   sources, and any applicable fallback information.
    func ask(_ question: String) async -> AssistantResponse
}
