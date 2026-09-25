//
// CloudModelEngine.swift
//
// Purpose:
// Future cloud inference provider.
//
// Why this exists:
// Keeps Vertex-specific networking isolated.
//

import Foundation

@MainActor
final class CloudModelEngine: AIModelEngineProtocol {

    var isAvailable: Bool { true }

    ///
    /// The identifier of the model currently active in this engine.
    ///
    /// Why this exists:
    /// `AIBrain.routeRequest` uses this to populate `ProviderMetadata.modelId`
    /// when wrapping cloud responses. Will be updated to the Vertex model in 5B.
    ///
    var currentModelId: String { model }

    // MARK: - Legacy Groq Configuration (To be removed in 5B)
    private var apiKey: String {
        Bundle.main.object(forInfoDictionaryKey: "GroqAPIKey") as? String ?? ""
    }
    private let groqEndpoint = URL(string: "https://api.groq.com/openai/v1/chat/completions")!
    private let model = "meta-llama/llama-4-scout-17b-16e-instruct"
    
    // MARK: - Future Vertex Configuration
    private let vertexEndpoint = "https://placeholder-vertex-endpoint.run.app"
    private var firebaseToken: String? { "placeholder_token" }
    private let defaultTimeout: TimeInterval = 30.0
    private let maxRetries: Int = 3

    ///
    /// Future Vertex chat endpoint.
    ///
    /// Why this exists:
    /// This placeholder will later call the AI Gateway running
    /// on Cloud Run while preserving the existing response format.
    ///
    /// - Parameters:
    ///   - prompt: The user's input.
    ///   - systemPrompt: The instructions for the model.
    /// - Returns: A generated string response.
    /// - Throws: `AIBrainError` if generation fails.
    func generateChat(prompt: String, systemPrompt: String) async throws -> String {
        let requestId = UUID().uuidString
        let _ = vertexEndpoint
        let _ = firebaseToken
        let _ = defaultTimeout
        let _ = maxRetries
        
        let messages: [[String: String]] = [
            ["role": "system",  "content": systemPrompt],
            ["role": "user",    "content": prompt]
        ]
        return try await request(messages: messages, maxTokens: 1024, temperature: 0.75)
    }

    ///
    /// Future Vertex JSON endpoint.
    ///
    /// Why this exists:
    /// Generates structured JSON outputs (e.g., for meal recommendations, daily goals).
    ///
    /// - Parameters:
    ///   - context: The serialized context string.
    ///   - schema: The expected JSON schema.
    ///   - instructions: The system instructions.
    /// - Returns: A raw JSON string.
    /// - Throws: `AIBrainError` if generation fails.
    func generateJSON(context: String, schema: String, instructions: String) async throws -> String {
        let requestId = UUID().uuidString
        let _ = vertexEndpoint
        let _ = firebaseToken
        let _ = defaultTimeout
        let _ = maxRetries
        
        let messages: [[String: String]] = [
            ["role": "system", "content": instructions + "\n\nIMPORTANT: Respond with ONLY a single valid JSON object matching this schema (no markdown, no extra text):\n" + schema],
            ["role": "user",   "content": context]
        ]
        return try await request(messages: messages, maxTokens: 1024, temperature: 0.5)
    }

    ///
    /// Future Vertex Vision endpoint.
    ///
    /// Why this exists:
    /// Processes images (e.g., food scanning) via Vertex AI.
    ///
    /// - Parameters:
    ///   - imageData: The image to process.
    ///   - prompt: The vision instructions.
    /// - Returns: A generated string describing the image.
    /// - Throws: `AIBrainError` if vision processing fails.
    func generateVision(imageData: Data, prompt: String) async throws -> String {
        let requestId = UUID().uuidString
        let _ = vertexEndpoint
        let _ = firebaseToken
        let _ = defaultTimeout
        let _ = maxRetries
        
        // Placeholder implementation for now
        throw AIBrainError.cloudGenerationFailed
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
        return try await generateJSON(context: context, schema: schema, instructions: instructions)
    }

    func generateDailyGoalsJSON(context: String, instructions: String) async throws -> String {
        let schema = """
        {"goals": [
          {"title": "string (1-3 words, sharp and direct)",
           "sentence": "string (max 12 words, include one real number from logs)",
           "category": "string (one of: nutrition, exercise, symptoms)"}
        ]}
        """
        return try await generateJSON(context: context, schema: schema, instructions: instructions)
    }

    func request(messages: [[String: String]], maxTokens: Int, temperature: Double) async throws -> String {
        guard !apiKey.isEmpty, apiKey != "YOUR_GROQ_API_KEY" else {
            throw AIBrainError.unauthorized
        }

        var req = URLRequest(url: groqEndpoint)
        req.httpMethod = "POST"
        req.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        req.addValue("application/json",  forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model":       model,
            "messages":    messages,
            "max_tokens":  maxTokens,
            "temperature": temperature
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: req)

        guard let http = response as? HTTPURLResponse else {
            throw AIBrainError.invalidCloudResponse
        }
        guard (200...299).contains(http.statusCode) else {
            let msg = String(data: data, encoding: .utf8) ?? "Unknown"
            print("❌ Groq API \(http.statusCode): \(msg)")
            throw AIBrainError.cloudGenerationFailed
        }

        guard
            let json    = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let choices = json["choices"] as? [[String: Any]],
            let first   = choices.first,
            let message = first["message"] as? [String: Any],
            let content = message["content"] as? String
        else {
            throw AIBrainError.parsingFailed
        }

        return content
    }
}
