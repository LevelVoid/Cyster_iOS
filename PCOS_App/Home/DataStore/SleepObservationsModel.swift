//
//  AICoachService.swift
//  PCOS_App
//
//  Created by Apple AI
//

import Foundation
import FoundationModels

class SleepObservationsModel {
    
    static let shared = SleepObservationsModel()
    private init() {}
    
    // System instructions tuned for PCOS and sleep behavior
    private let systemInstructions = """
    You are a supportive AI health coach specializing in PCOS and sleep.

    Observe the user's recent sleep durations and generate ONE short insight about today's likely energy, hormone balance, or insulin stability.

    Rules:
    - Write exactly one sentence.
    - Maximum 18 words.
    - Friendly, calm tone.
    - No medical claims or diagnosis.
    - No lists, markdown, emojis, or extra formatting.
    - Focus on pattern observation, not advice.

    Example style:
    "Consistent 7–8 hour sleep may support steadier energy and hormone balance today."
    """
    
    /// Prepares the AI prompt string based on the current merged sleep map
    private func generateSleepPrompt(from chartData: [SleepChartDataModel]) -> String {
        var prompt = "Here are the user's sleep durations in hours for the selected time range:\n"
        
        for point in chartData {
            prompt += "- \(point.label): \(String(format: "%.1f", point.hours)) hours\n"
        }
        
        return prompt
    }
    
    /// Invokes the native iOS LanguageModelSession to evaluate the sleep records and yield an insight string
    func fetchSleepInsight(chartData: [SleepChartDataModel]) async throws -> String {
        guard !chartData.isEmpty else {
            return "Log more sleep data to unlock personalized insights!"
        }
        
        let prompt = generateSleepPrompt(from: chartData)
        let session = LanguageModelSession(instructions: systemInstructions)
        
        do {
            let result = try await session.respond(to: prompt)
            return result.content.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            print("ERROR: Foundation Model failed to analyze sleep: \(error)")
            throw error
        }
    }
}
