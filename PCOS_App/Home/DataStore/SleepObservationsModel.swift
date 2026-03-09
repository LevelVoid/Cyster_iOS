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
    You are a professional health and sleep AI coach specializing in PCOS.
    Look at the provided sleep durations for the user.
    Write a single, highly concise, friendly sentence observing these sleep patterns and how it might impact the user's energy, insulin stability, or hormone balance today.
    Be encouraging and supportive. Do not use markdown, lists, or extra formatting. Be very brief (max 20 words).
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
