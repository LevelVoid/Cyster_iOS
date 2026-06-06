import Foundation

@MainActor
final class CloudModelEngine: AIModelEngineProtocol {

    var isAvailable: Bool { true }

    private var apiKey: String {
        Bundle.main.object(forInfoDictionaryKey: "GroqAPIKey") as? String ?? ""
    }

    private let endpoint = URL(string: "https://api.groq.com/openai/v1/chat/completions")!
    private let model    = "meta-llama/llama-4-scout-17b-16e-instruct"

    func generate(prompt: String, systemPrompt: String) async throws -> String {
        let messages: [[String: String]] = [
            ["role": "system",  "content": systemPrompt],
            ["role": "user",    "content": prompt]
        ]
        return try await request(messages: messages, maxTokens: 1024, temperature: 0.75)
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
        let messages: [[String: String]] = [
            ["role": "system", "content": instructions + "\n\nIMPORTANT: Respond with ONLY a single valid JSON object matching this schema (no markdown, no extra text):\n" + schema],
            ["role": "user",   "content": context]
        ]
        return try await request(messages: messages, maxTokens: 1024, temperature: 0.5)
    }

    func generateDailyGoalsJSON(context: String, instructions: String) async throws -> String {

        let schema = """
        {"goals": [
          {"title": "string (1-3 words, sharp and direct)",
           "sentence": "string (max 12 words, include one real number from logs)",
           "category": "string (one of: nutrition, exercise, symptoms)"}
        ]}
        """
        let messages: [[String: String]] = [
            ["role": "system", "content": instructions + "\n\nIMPORTANT: Respond with ONLY a single valid JSON object matching this schema (no markdown, no extra text):\n" + schema],
            ["role": "user",   "content": context]
        ]
        return try await request(messages: messages, maxTokens: 512, temperature: 0.5)
    }

    func request(messages: [[String: String]], maxTokens: Int, temperature: Double) async throws -> String {
        guard !apiKey.isEmpty, apiKey != "YOUR_GROQ_API_KEY" else {
            throw CloudEngineError.missingAPIKey
        }

        var req = URLRequest(url: endpoint)
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
            throw CloudEngineError.invalidResponse
        }
        guard (200...299).contains(http.statusCode) else {
            let msg = String(data: data, encoding: .utf8) ?? "Unknown"
            print("❌ Groq API \(http.statusCode): \(msg)")
            throw CloudEngineError.apiError(statusCode: http.statusCode)
        }

        guard
            let json    = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let choices = json["choices"] as? [[String: Any]],
            let first   = choices.first,
            let message = first["message"] as? [String: Any],
            let content = message["content"] as? String
        else {
            throw CloudEngineError.parsingFailed
        }

        return content
    }
}

enum CloudEngineError: LocalizedError {
    case missingAPIKey
    case invalidResponse
    case apiError(statusCode: Int)
    case parsingFailed

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:         return "Groq API key is not configured. Add it to Secrets.xcconfig."
        case .invalidResponse:       return "Received an invalid response from Groq."
        case .apiError(let code):    return "Groq API request failed with status \(code)."
        case .parsingFailed:         return "Failed to parse the Groq API response."
        }
    }
}
