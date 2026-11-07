//
//  ReferenceServiceProtocol.swift
//  RigAssistAI
//
//  Defines the interface contract for accessing the application's
//  bundled, approved rigging reference information.
//

import Foundation

/// Defines the operations available to components that need access
/// to the approved local reference dataset.
///
/// The protocol keeps the SwiftUI interface and AI Service independent
/// from the concrete implementation of reference-data storage and retrieval.
protocol ReferenceServiceProtocol {

    /// Disclaimer associated with the currently loaded reference dataset.
    var disclaimer: String { get }

    /// Returns a single verified reference record matching the supplied ID.
    ///
    /// - Parameter id: Unique identifier of the requested reference record.
    /// - Returns: The matching verified ReferenceRecord, or nil when no
    ///   verified record exists with the supplied ID.
    func record(id: String) -> ReferenceRecord?

    /// Searches the approved reference dataset for verified records that
    /// match the supplied query.
    ///
    /// - Parameters:
    ///   - query: User-entered search text.
    ///   - limit: Maximum number of records to return.
    /// - Returns: Matching verified ReferenceRecord values, up to the
    ///   requested limit.
    func search(query: String, limit: Int) -> [ReferenceRecord]
}
