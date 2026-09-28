//
// AIModelEngine.swift
//
// Purpose:
// Defines the provider-agnostic inference protocol all AI engines must conform to.
//
// Why this exists:
// Ensures AIBrain can route between Foundation Models, Cloud (Groq/Vertex),
// or any future engine through a single, stable interface without knowing
// implementation details of each provider.
//

import Foundation

///
/// Defines the minimum interface every AI inference provider must implement.
///
/// Why this exists:
/// Decouples `AIBrain` from concrete engine implementations so providers can
/// be swapped, added, or mocked without changing the routing layer.
///
protocol AIModelEngineProtocol {

    ///
    /// Whether this engine is currently available and able to accept requests.
    ///
    var isAvailable: Bool { get }

    ///
    /// Generates a plain-text response to the given prompt.
    ///
    /// - Parameters:
    ///   - prompt: The user's input text.
    ///   - systemPrompt: The behavioral instructions for this engine.
    /// - Returns: The generated response string.
    /// - Throws: `AIBrainError` if generation fails.
    ///
    func generate(prompt: String, systemPrompt: String) async throws -> String

    ///
    /// Generates a JSON string for meal recommendations.
    ///
    /// - Parameters:
    ///   - context: Serialised context containing today's macro gaps.
    ///   - instructions: System-level rules the engine must follow.
    /// - Returns: A raw JSON string matching the meal recommendation schema.
    /// - Throws: `AIBrainError` if generation fails.
    ///
    func generateMealRecommendationsJSON(context: String, instructions: String) async throws -> String

    ///
    /// Generates a JSON string for daily health goals.
    ///
    /// - Parameters:
    ///   - context: Serialised context containing today's logs and targets.
    ///   - instructions: System-level rules the engine must follow.
    /// - Returns: A raw JSON string matching the daily goals schema.
    /// - Throws: `AIBrainError` if generation fails.
    ///
    func generateDailyGoalsJSON(context: String, instructions: String) async throws -> String
}
