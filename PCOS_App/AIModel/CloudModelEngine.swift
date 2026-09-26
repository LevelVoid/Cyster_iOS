//
// CloudModelEngine.swift
//
// Purpose:
// Cloud inference provider.
//
// Why this exists:
// Keeps Vertex-specific networking isolated.
//

import Foundation
import FirebaseAuth

@MainActor
final class CloudModelEngine: AIModelEngineProtocol {

    var isAvailable: Bool { true }

    var currentModelId: String { "gemini-2.5-flash" }

    // MARK: - Vertex Configuration
    private let gatewayEndpoint = "https://ai-gateway-1024644064258.us-central1.run.app"
    private let defaultTimeout: TimeInterval = 30.0
    private let maxRetries: Int = 3
    
    // Auth helper
    private func fetchFirebaseToken() async throws -> String {
        guard let user = Auth.auth().currentUser else {
            throw AIBrainError.unauthorized
        }
        do {
            return try await user.getIDToken()
        } catch {
            throw AIBrainError.unauthorized
        }
    }
    
    ///
    /// Purpose:
    /// Generic request helper for the AI Gateway.
    ///
    /// Why:
    /// Centralizes URLSession logic, JWT injection, X-Request-ID propagation,
    /// and exponential backoff retry logic.
    ///
    /// - Parameters:
    ///   - endpoint: The relative path to the AI Gateway.
    ///   - body: The JSON request body payload.
    /// - Returns: The raw Data returned by the server.
    /// - Throws: `AIBrainError` mapped from HTTP status codes or networking errors.
    ///
    private func performRequest(endpoint: String, body: [String: Any]) async throws -> Data {
        let token = try await fetchFirebaseToken()
        guard let url = URL(string: "\(gatewayEndpoint)/\(endpoint)") else {
            throw AIBrainError.cloudGenerationFailed
        }
        
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        req.addValue(UUID().uuidString, forHTTPHeaderField: "X-Request-ID")
        req.timeoutInterval = defaultTimeout
        
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        var attempts = 0
        let maxAttempts = maxRetries + 1
        let backoffs: [UInt64] = [500_000_000, 1_000_000_000, 2_000_000_000] // 0.5s, 1s, 2s
        
        while attempts < maxAttempts {
            do {
                let (data, response) = try await URLSession.shared.data(for: req)
                guard let http = response as? HTTPURLResponse else {
                    throw AIBrainError.invalidCloudResponse
                }
                
                switch http.statusCode {
                case 200...299:
                    return data
                case 400:
                    throw AIBrainError.cloudGenerationFailed
                case 401, 403:
                    throw AIBrainError.unauthorized
                case 502, 503, 504:
                    throw AIBrainError.requestTimedOut
                default:
                    throw AIBrainError.cloudGenerationFailed
                }
            } catch let error as AIBrainError {
                switch error {
                case .unauthorized, .cloudGenerationFailed, .invalidCloudResponse:
                    throw error
                default:
                    attempts += 1
                    if attempts < maxAttempts {
                        try await Task.sleep(nanoseconds: backoffs[attempts - 1])
                    } else {
                        throw error
                    }
                }
            } catch {
                attempts += 1
                if attempts < maxAttempts {
                    try await Task.sleep(nanoseconds: backoffs[attempts - 1])
                } else {
                    let nsError = error as NSError
                    if nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorTimedOut {
                        throw AIBrainError.requestTimedOut
                    }
                    throw AIBrainError.cloudGenerationFailed
                }
            }
        }
        throw AIBrainError.cloudGenerationFailed
    }

    ///
    /// Purpose:
    /// Sends a chat message with history to the AI Gateway and returns the generated text.
    ///
    /// Why:
    /// Supports the conversational coaching interface using Vertex AI.
    ///
    /// - Parameters:
    ///   - prompt: The user's input text.
    ///   - systemPrompt: The persona instructions.
    /// - Returns: The AI's generated response string.
    /// - Throws: `AIBrainError` if networking or decoding fails.
    ///
    func generateChat(prompt: String, systemPrompt: String, history: [[String: String]] = []) async throws -> String {
        let body: [String: Any] = [
            "prompt": prompt,
            "system_prompt": systemPrompt,
            "history": history
        ]
        
        let data = try await performRequest(endpoint: "chat", body: body)
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let text = json["text"] as? String else {
            throw AIBrainError.parsingFailed
        }
        return text
    }

    ///
    /// Purpose:
    /// Requests a structured JSON recommendation from the backend.
    ///
    /// Why:
    /// Used for specific AI features (e.g., Daily Goals, Meal Recommendations)
    /// that require rigid JSON structures rather than free-text.
    ///
    /// - Parameters:
    ///   - type: The recommendation type (e.g., "meal_recommendations").
    ///   - context: The serialized string context of user data.
    ///   - schema: The JSON schema to enforce on the output.
    /// - Returns: A JSON string containing the structured response.
    /// - Throws: `AIBrainError` if generation or validation fails.
    ///
    func generateRecommendation(type: String, context: String, schema: String) async throws -> String {
        let body: [String: Any] = [
            "type": type,
            "context": context,
            "schema": schema
        ]
        
        let data = try await performRequest(endpoint: "recommendation", body: body)
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let output = json["output"] as? [String: Any] else {
            throw AIBrainError.parsingFailed
        }
        
        // Serialize back to string for legacy methods
        let outputData = try JSONSerialization.data(withJSONObject: output)
        return String(data: outputData, encoding: .utf8) ?? ""
    }
    
    ///
    /// Purpose:
    /// Parses natural language food descriptions into a structured `Food` domain model.
    ///
    /// Why:
    /// Allows users to log meals by typing rather than searching databases.
    ///
    /// - Parameter text: The free-form meal description.
    /// - Returns: A structured `Food` object.
    /// - Throws: `AIBrainError` if the parsing fails.
    ///
    func analyzeText(text: String) async throws -> Food {
        let body: [String: Any] = [
            "text": text
        ]
        
        let data = try await performRequest(endpoint: "analyze/text", body: body)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(Food.self, from: data)
    }

    ///
    /// Purpose:
    /// Analyzes an image of a meal and returns a structured `Food` domain model.
    ///
    /// Why:
    /// Replaces the inaccurate linear classifier pipeline with Vertex Vision.
    ///
    /// - Parameters:
    ///   - imageData: The JPEG/PNG data of the food image.
    ///   - prompt: The analytical instructions for the vision model.
    /// - Returns: A structured `Food` object containing ingredients and macros.
    /// - Throws: `AIBrainError` if image processing fails.
    ///
    func generateVision(imageData: Data, prompt: String) async throws -> Food {
        let base64 = imageData.base64EncodedString()
        let body: [String: Any] = [
            "image_base64": base64
        ]
        
        let data = try await performRequest(endpoint: "analyze/image", body: body)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(Food.self, from: data)
    }
    
    // MARK: - Legacy Methods (Used for current compatibility)

    func generate(prompt: String, systemPrompt: String) async throws -> String {
        return try await generateChat(prompt: prompt, systemPrompt: systemPrompt)
    }

    func generateMealRecommendationsJSON(context: String, instructions: String) async throws -> String {
        let schema = """
        {"observationLine": "string (max 12 words referencing logged numbers)",
         "subObservationLine": "string (short encouragement, max 12 words)",
         "foods": [
           {"name": "string (Indian dish, max 25 chars)",
            "primaryMacro": "string (e.g. '22g protein')",
            "description": "string (5-8 words)",
            "calories": "string (e.g. '420 kcal')",
            "impactTag": "string (one of: High Protein, Low GI, High Fibre, Healthy Fats, Whole Food)",
            "colorHint": "string (one word: red or green or yellow)"}
         ]}
        """
        return try await generateRecommendation(type: "meal_recommendations", context: context, schema: schema)
    }

    func generateDailyGoalsJSON(context: String, instructions: String) async throws -> String {
        let schema = """
        {"goals": [
          {"id": "string (stable snake_case ID e.g. protein_today)",
           "title": "string (1-3 words, sharp and direct)",
           "sentence": "string (max 12 words, include one real number from logs)",
           "category": "string (one of: nutrition, exercise, symptoms)",
           "targetType": "string (one of: protein, workoutMinutes, steps, symptom, manual)",
           "targetValue": "number (threshold to reach, 0 for symptom/manual)",
           "currentValue": "number (user's current progress at generation time)",
           "completionRule": "string (one of: current>=target, any, manual)",
           "celebrationMessage": "string (max 6 words, e.g. Protein goal achieved!)"}
        ]}
        """
        return try await generateRecommendation(type: "daily_goals", context: context, schema: schema)
    }
}
