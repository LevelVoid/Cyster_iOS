import Foundation

protocol AIModelEngineProtocol {

    var isAvailable: Bool { get }

    func generate(prompt: String, systemPrompt: String) async throws -> String

    func generateMealRecommendationsJSON(context: String, instructions: String) async throws -> String

    func generateDailyGoalsJSON(context: String, instructions: String) async throws -> String
}
