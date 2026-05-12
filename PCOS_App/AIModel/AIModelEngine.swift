import Foundation

// MARK: - Engine Protocol
/// Abstracts both the on-device (FoundationModels) and cloud (Groq) AI backends.
/// AIBrain uses this protocol exclusively — it never talks to either engine directly.
protocol AIModelEngineProtocol {
    /// True if this engine is ready to accept requests right now.
    var isAvailable: Bool { get }

    /// Send a single-turn prompt and get a plain-text response.
    func generate(prompt: String, systemPrompt: String) async throws -> String

    /// Generate structured meal recommendations as JSON.
    func generateMealRecommendationsJSON(context: String, instructions: String) async throws -> String

    /// Generate structured daily goals as JSON.
    func generateDailyGoalsJSON(context: String, instructions: String) async throws -> String
}
