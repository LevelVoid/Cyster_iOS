import Foundation
import FoundationModels

@MainActor
final class AIBrain {

    static let shared = AIBrain()
    private init() {}

    private var foundationModelsAvailable: Bool {
        if case .available = SystemLanguageModel.default.availability { return true }
        return false
    }

    private let cloudEngine = CloudModelEngine()

    private var chatSession: LanguageModelSession?

    private var cloudChatHistory: [[String: String]] = []

    private var systemPrompt: String {
        """
        You are a compassionate and evidence-based PCOS health coach. You are warm, \
        non-judgmental, and knowledgeable about PCOS specifically for Indian women.

        PERSONALITY:
        - Speak with calm confidence — you know PCOS deeply, own that knowledge
        - Never start with "I'm sorry", "Unfortunately", "I can't", or any apology
        - Never hedge with "I think", "perhaps", "you might want to consider" — give direct advice
        - Warm and supportive, but authoritative — like a knowledgeable friend, not a disclaimer bot
        - Use "you" language, never preachy
        - Celebrate small wins enthusiastically
        - Never shame about food choices or weight
        - Treat cravings as a PCOS symptom, not a personal failing

        MEDICAL BOUNDARIES:
            - Never diagnose or prescribe medication doses
            - For medical decisions, say "your doctor can confirm this" — not "you must see a doctor"
            - For prolonged amenorrhea (>3 months), flag medical review naturally in conversation
            - For mental health crisis signals, gently direct to professional support

            RESPONSE STYLE:
            - Lead with the answer, then explain — never lead with a caveat
            - Use **bold** for key food names, nutrients, and action items
            - Keep responses to 3-5 sentences for simple questions; use structured format only when listing 3+ items
            - End with one specific actionable suggestion or a focused question
            - NEVER use emojis, unicode symbols, or special formatting characters like [?]
            - Use standard bullet points (-) instead of asterisks (*) for lists.
            - Do not wrap your response in quotation marks.

            FOOD RULES:
            - Always recommend Indian foods: rajma, dahi, moong dal, palak, methi, alsi, pudina, haldi, adrak, amla, ragi, jowar
            - Always include Hindi name alongside English: "flaxseed (alsi)"
            - Only recommend Western foods when no Indian equivalent exists

            CONTEXT USAGE:
            - The health context block is BACKGROUND DATA ONLY — do NOT respond to it
            - ALWAYS answer what the user explicitly asked — that is the topic
            - Only reference context data when it is directly relevant to the question asked
            - If user asks about their next period: answer the period question using cycle data, do not pivot to symptoms
            - If user asks about food: answer the food question, you may reference symptoms as supporting context
            - Never summarise or respond to the context block itself

        BMI-AWARE ADVICE:
        - ALWAYS check BMI category in context before any weight-related suggestion
        - BMI "Normal weight" or "Underweight": NEVER suggest weight loss, calorie restriction, or weight management
        - For Normal/Underweight: focus only on food quality, nutrient density, hormonal balance
        - BMI "Overweight" or "Obese": you may mention that modest weight loss supports cycle regularity, but keep it brief and non-shaming
        - When in doubt, do not mention weight at all — focus on the nutrient being discussed

        QUESTIONS YOU MUST ALWAYS ANSWER DIRECTLY:
        - "When is my next period" → read "Next period:" from context and state the date directly
        - "When will I ovulate" → subtract 14 days from the next period date in context and state it
        - "What phase am I in" → read "Current phase:" from context and explain it warmly
        - "What cycle day am I on" → read "Current cycle day:" from context and state it
        - These are data-retrieval questions, NOT medical advice. The data is already in your context.
        - Never redirect period timing questions to a doctor — you have the prediction data, use it.

        AGE-AWARE ADVICE:
        - Check age in context before every response
        - Age < 20: she is a teenager — avoid any weight or body-focused language entirely, focus on cycle regularity and energy. Always recommend she involve a parent/doctor for any supplement suggestions.
        - Age 20-25: early adulthood, fertility and cycle regularity are likely concerns. Hormonal education is welcome.
        - Age 26-35: may be actively thinking about fertility. Mention fertility-supportive foods naturally when relevant.
        - Age > 35: mention perimenopause awareness only if directly relevant. Emphasise long-term metabolic health.
        - Never mention age explicitly in your response unless the user brings it up.

        PCOS PHENOTYPE-AWARE ADVICE:
        - ALWAYS check PCOS type in context and tailor advice accordingly.

        Type A (Hyperandrogenism + Anovulation + PCO — highest insulin resistance):
        - Prioritise low-GI foods, insulin-sensitising nutrients (inositol, zinc, chromium)
        - Recommend strength training + HIIT but cap at 40-45 min to avoid cortisol spike
        - Spearmint (pudina) chai is directly relevant — reduces free testosterone
        - Flag that dietary consistency matters more than perfection for Type A

        Type B (Hyperandrogenism + Anovulation — adrenal-dominant):
        - Stress and cortisol are the primary drivers — always acknowledge this
        - Recommend cortisol-reducing foods: ashwagandha, dark chocolate (small amounts), magnesium-rich foods (til, rajma)
        - Exercise: yoga and walking over HIIT — excess exercise raises cortisol further for Type B
        - Sleep timing is therapeutically important for Type B — mention this when sleep comes up

        Type C (Hyperandrogenism + PCO — mildest metabolic impact):
        - Androgen reduction is the focus: flaxseed (alsi), spearmint (pudina), zinc-rich foods
        - Moderate carb approach works well — no need for aggressive low-GI restriction
        - Skin and hair symptoms (acne, hirsutism) are most likely concerns for Type C

        Type D (Anovulation + PCO — non-hyperandrogenic):
        - No elevated androgens, so hair/skin focus is less relevant
        - Cycle regularity and ovulation support are the primary goals
        - Inositol-rich foods (rajma, chickpeas) and stress management are most impactful
        - Yoga and steady-state cardio work well — no cortisol concern

        Unknown phenotype:
        - Take a conservative approach: low-GI, anti-inflammatory, high-fibre
        - Do not make strong claims about androgens or insulin resistance without knowing type
        - Gently encourage the user to get a proper diagnosis if phenotype is unknown
            BANNED PHRASES — never use these:
            - "I'm sorry"
            - "Unfortunately"  
            - "I cannot"
        CONVERSATION STYLE:
        - If the user sends a greeting ("hey", "hi", "hello", "how are you") — respond warmly and briefly, like a friend. Ask how they're doing. Do NOT jump into health advice unprompted.
        - If the user is making small talk — match their energy. Be human, be warm, keep it short.
        - Only bring in health context when the user asks a health-related question or mentions a symptom/food/cycle.
        - Do NOT proactively mention their logs, symptoms, or data unless they ask about it.
        - A simple "hey" deserves a simple "hey back" — not a health lecture.

        """
    }

    func sendChatMessage(_ text: String, context: String) async throws -> String {

        let trimmed    = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let wordCount  = trimmed.components(separatedBy: .whitespaces).filter { !$0.isEmpty }.count
        let casualPhrases = [
            "hey", "hi", "hello", "hii", "heyy", "how are you",
            "what's up", "sup", "good morning", "good night",
            "thanks", "thank you", "haha", "lol",
            "yes", "no", "yeah", "nope", "sure", "okay", "ok",
            "please", "go ahead", "tell me", "yes please",
            "no thanks", "that's fine", "sounds good", "great",
            "not really", "maybe", "i think so", "definitely"
        ]
        let isCasual = casualPhrases.contains(where: { trimmed == $0 || trimmed.hasPrefix($0 + " ") })
                      || wordCount <= 2

        let contextualMessage: String
        if isCasual {
            contextualMessage = text
        } else {
            let isPeriodQuestion = trimmed.contains("period") ||
                                   trimmed.contains("next cycle") ||
                                   trimmed.contains("ovulat")
            var periodHint = ""
            if isPeriodQuestion,
               let range    = context.range(of: "Next period:"),
               let endRange = context.range(of: "\n", range: range.upperBound..<context.endIndex) {
                let periodLine = String(context[range.lowerBound..<endRange.lowerBound])
                periodHint = "\n[Relevant data: \(periodLine)]"
            }
            contextualMessage = """
            [BACKGROUND HEALTH DATA — use only if relevant to the question below:]
            \(context)\(periodHint)
            [END BACKGROUND DATA]

            User's question: \(text)
            """
        }

        if foundationModelsAvailable {

            if chatSession == nil {
                chatSession = LanguageModelSession(
                    tools: [PCOSResearchTool(), IndianFoodTool()],
                    instructions: systemPrompt
                )
            }
            do {
                let response = try await chatSession!.respond(to: contextualMessage)
                return response.content
            } catch {
                print("⚠️ FoundationModels chat failed (\(error)), falling back to Cloud")
                chatSession = nil

            }
        }

        if cloudChatHistory.isEmpty {
            cloudChatHistory = [["role": "system", "content": systemPrompt]]
        }
        cloudChatHistory.append(["role": "user", "content": contextualMessage])
        do {
            let reply = try await cloudEngine.request(
                messages: cloudChatHistory,
                maxTokens: 1024,
                temperature: 0.75
            )
            cloudChatHistory.append(["role": "assistant", "content": reply])
            return reply
        } catch {
            cloudChatHistory.removeLast()
            throw error
        }
    }

    private var mealInstructions: String { """
        Generate exactly 3 personalized Indian meal suggestions based on the user's PCOS context.

        CONTEXT DATA:
        - Meals eaten today with macro gaps
        - Protein/Macro targets vs actuals
        - PCOS phenotype and cycle phase
        - Current symptoms

        RULES:
        - Provide exactly 3 AUTHENTIC INDIAN food suggestions. No Western foods (no turkey chili, osso buco, etc.).
        - Do NOT repeat any food already logged today.
        - Use short dish names (max 25 characters). E.g. 'Moong Dal Chilla', 'Palak Paneer', 'Ragi Roti'.
        - primaryMacro: Must be a metric based on the nutritional gap (e.g. "22g protein", "8g fibre").
        - description: A 5-8 word description of the dish.
        - calories: Estimated calorie count per serving (e.g. "420 kcal").
        - emoji: A single relevant food emoji.

        FOOD SELECTION PRIORITY:
        - Analyze the Gap values in the context.
        - CRITICAL RULE: If a Gap is 0g (e.g. Carbs Gap: 0g), it means the user has already exceeded their daily limit. You MUST NOT suggest foods high in that macro!
        - If Carbs Gap is 0g, ALL 3 suggestions MUST be extremely low carb (NO rice, NO roti, NO bread, NO potatoes).
        - If Fats Gap is 0g, avoid heavy curries or fried items.
        - Focus heavily on the nutrient with the LARGEST remaining gap (e.g., if Protein Gap is largest, prioritize protein-heavy dishes).
        - Ensure variety, but never violate the 0g gap rule.

        IMPACT TAG RULES — Allowed tags: High Protein, Low GI, High Fibre, Healthy Fats, Whole Food
        - High Protein → dal, paneer, eggs, chicken, legumes
        - Low GI → ragi, oats, whole grains
        - High Fibre → vegetables, salads, legumes
        - Healthy Fats → ONLY nut/seed/oil-based dishes. NEVER for paneer, dal, eggs, chicken.
        - Whole Food → minimally processed balanced meals

        OBSERVATION LINE: Output any short phrase. It will be overridden by the app.
        SUB OBSERVATION LINE: Output any short phrase. It will be overridden by the app.
        """ }

    func generateMealRecommendations(context: String) async throws -> MealRecommendationOutput {
        if foundationModelsAvailable {
            do {

                let session = LanguageModelSession(instructions: mealInstructions)
                let response = try await session.respond(
                    to: context,
                    generating: MealRecommendationOutput.self
                )
                return response.content
            } catch {
                print("⚠️ FoundationModels meal generation failed (\(error)), falling back to Cloud")

            }
        }

        let jsonString = try await cloudEngine.generateMealRecommendationsJSON(
            context: context,
            instructions: mealInstructions
        )
        return try parseMealJSON(jsonString)
    }

    private func parseMealJSON(_ raw: String) throws -> MealRecommendationOutput {

        var clean = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if clean.hasPrefix("```") {
            clean = clean.components(separatedBy: "\n").dropFirst().joined(separator: "\n")
            if clean.hasSuffix("```") { clean = String(clean.dropLast(3)) }
        }
        guard let data = clean.data(using: .utf8),
              let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw AIBrainError.parsingFailed
        }

        let obs    = json["observationLine"]    as? String ?? ""
        let subObs = json["subObservationLine"] as? String ?? ""
        let rawFoods = json["foods"] as? [[String: Any]] ?? []

        let foods: [FoodCard] = rawFoods.compactMap { s in
            guard
                let name         = s["name"]         as? String,
                let primaryMacro = s["primaryMacro"]  as? String,
                let description  = s["description"]   as? String,
                let calories     = s["calories"]      as? String,
                let impactTag    = s["impactTag"]     as? String,
                let colorHint    = s["colorHint"]     as? String
            else { return nil }
            return FoodCard(
                name: name,
                primaryMacro: primaryMacro,
                description: description,
                calories: calories,
                impactTag: impactTag,
                colorHint: colorHint
            )
        }
        return MealRecommendationOutput(
            observationLine: obs,
            subObservationLine: subObs,
            foods: foods
        )
    }

    private var goalsInstructions: String { """
        Generate exactly 2 personalized daily health goals for a woman with PCOS.

        PRIORITY ORDER — pick the top 2 that apply, in this order:
        1. Diet-symptom connection: active symptom today + a food/nutrition change that addresses it
        2. Diet-workout connection: a workout was logged + a protein/recovery nutrition gap exists
        3. Nutrition gap: a macro target (protein, fibre) is significantly unmet today
        4. Workout gap: no strength training or movement logged in the past 7 days

        HARD RULES:
        - CRITICAL: Use ONLY the exact numbers from the context. Read protein target from the "Targets: ...PXg..." line. Never invent or assume typical values.
        - Never generate a sleep goal — sleep is excluded entirely
        - ONLY generate goals based on data explicitly present in the context.
        - If "Symptoms today: none" — do not generate any symptom-based goal.
        - Never invent or assume symptoms, food logs, or patterns not in the context.
        - Never suggest weight loss or calorie restriction if BMI is Underweight or Normal.
        - Both goals must be different categories (nutrition / exercise / symptoms).
        - Sentences must be under 12 words. No vague goals — name a specific food or action.
        - icon: Use a valid SF Symbol name (e.g. "fork.knife", "figure.walk", "heart.fill").
        """ }

    func generateDailyGoals(context: String) async throws -> DailyGoalsOutput {
        if foundationModelsAvailable {
            do {
                let session = LanguageModelSession(instructions: goalsInstructions)
                let response = try await session.respond(
                    to: context,
                    generating: DailyGoalsOutput.self
                )
                return response.content
            } catch {
                print("⚠️ FoundationModels goals generation failed (\(error)), falling back to Cloud")

            }
        }

        let jsonString = try await cloudEngine.generateDailyGoalsJSON(
            context: context,
            instructions: goalsInstructions
        )
        return try parseGoalsJSON(jsonString)
    }

    private func parseGoalsJSON(_ raw: String) throws -> DailyGoalsOutput {
        var clean = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if clean.hasPrefix("```") {
            clean = clean.components(separatedBy: "\n").dropFirst().joined(separator: "\n")
            if clean.hasSuffix("```") { clean = String(clean.dropLast(3)) }
        }
        guard let data = clean.data(using: .utf8),
              let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let rawGoals = json["goals"] as? [[String: Any]] else {
            throw AIBrainError.parsingFailed
        }
        let goals: [GoalCard] = rawGoals.compactMap { g in
            guard
                let title    = g["title"]    as? String,
                let sentence = g["sentence"]  as? String,
                let category = g["category"] as? String
            else { return nil }
            return GoalCard(title: title, sentence: sentence, category: category)
        }
        return DailyGoalsOutput(goals: goals)
    }

    func generateResponse(prompt: String, instructions: String) async throws -> String {
        if foundationModelsAvailable {
            do {
                let session = LanguageModelSession(instructions: instructions)
                let response = try await session.respond(to: prompt)
                return response.content
            } catch {
                print("⚠️ FoundationModels generation failed (\(error)), falling back to Cloud")
            }
        }
        return try await cloudEngine.generate(prompt: prompt, systemPrompt: instructions)
    }

    func analyzeMealDescription(description: String, instructions: String) async throws -> String {
        if foundationModelsAvailable {
            do {
                let session = LanguageModelSession(instructions: instructions)
                let response = try await session.respond(to: description)
                return response.content
            } catch {
                print("⚠️ FoundationModels meal parsing failed (\(error)), falling back to Cloud")

            }
        }

        return try await cloudEngine.generate(prompt: description, systemPrompt: instructions)
    }

    func resetChat() {
        chatSession = nil
        cloudChatHistory = []
    }

    var isAvailable: Bool {
        foundationModelsAvailable || cloudEngine.isAvailable
    }
}

enum AIBrainError: LocalizedError {
    case modelUnavailable
    case parsingFailed

    var errorDescription: String? {
        switch self {
        case .modelUnavailable:
            return "No AI engine is available. Please check your internet connection or enable Apple Intelligence."
        case .parsingFailed:
            return "Failed to parse the AI response. Please try again."
        }
    }
}
