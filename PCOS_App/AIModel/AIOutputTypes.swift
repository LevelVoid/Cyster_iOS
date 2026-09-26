//
// AIOutputTypes.swift
//
// Purpose:
// Defines structured output models for AI generations.
//
// Why this exists:
// Standardizes AI output contracts across all features and provides
// a provider-neutral wrapper for generation metadata.
//

import Foundation
import FoundationModels

@Generable
struct MealRecommendationOutput {
    @Guide(description: """
    One sentence, max 12 words, referencing actual logged numbers from context.
    E.g. 'You have logged only 20g protein against your 60g target.'
    Use ONLY numbers present in the context — never invent values.
    Do not use colon for last meal.
    """)
    var observationLine: String

    @Guide(description: "One short sentence, max 12 words, encouraging the user. E.g. 'Add a high-protein meal to stay on track.'")
    var subObservationLine: String

    @Guide(description: """
    Exactly 3 Indian food suggestions. 
    None of these should repeat any food already logged today in the context.
    Each must directly address the focus tag gap.
    """)
    var foods: [FoodCard]
}

@Generable
struct FoodCard {
    @Guide(description: "Short Indian dish name, max 25 characters. E.g. 'Moong Dal Chilla', 'Palak Paneer', 'Ragi Roti'. Never suggest a food already logged today.")
    var name: String

    @Guide(description: "Metric based on the nutritional gap (e.g. '22g protein', '8g fibre').")
    var primaryMacro: String

    @Guide(description: "One short sentence describing the meal. E.g. 'Comforting lentil stew with spices'.")
    var description: String

    @Guide(description: "Estimated calorie count. E.g. '420 kcal'.")
    var calories: String

    @Guide(description: "Exactly 1 short, relevant PCOS tag (e.g. 'Low GI').")
    var impactTag: String

    @Guide(description: "One word only: red | green | yellow.")
    var colorHint: String
}

@Generable
struct DailyGoalsOutput {
    @Guide(description: """
    Exactly 2 goals. Priority order — pick the top 2 that apply:
    1. Diet + symptom connection (e.g. anti-inflammatory food for active cramps/bloating)
    2. Diet + workout connection (e.g. protein gap after a workout session)
    3. Nutrition gap (e.g. protein or fibre deficit from today's logs)
    4. Workout gap (e.g. no strength training this week)
    Never include sleep. Never include more than 2 goals.

    STEP 1 — Extract from context:
    - Symptoms today: [list from context — if none, note that]
    - Protein logged vs target: [exact numbers from context]
    - Workout minutes logged today: [number from context]
    - Strength sessions this week: [number from context]
    - Recent behavior: [workouts per week, avg protein]

    STEP 2 — Choose the smallest meaningful improvement.
    Never increase today's challenge by more than 30% compared to recent behavior.

    STEP 3 — Generate exactly 2 missions using only the extracted numbers above.
    """)
    var goals: [GoalCard]
}

@Generable
struct GoalCard {
    /// Stable identifier used for persistence (e.g. "protein_today", "workout_today").
    @Guide(description: "Stable snake_case ID. E.g. 'protein_today', 'workout_today', 'cramps_relief'. Must be unique within the two goals.")
    var id: String

    @Guide(description: "1-3 word title. Sharp and direct. If larger words then only 2 or 1 word title will be shown. E.g. 'Boost protein now', 'Ease cramps', 'Strength training'.")
    var title: String

    @Guide(description: """
    One action sentence, max 12 words. Include one real number from their logs.
    Be warm and encouraging — frame it as an opportunity, not a deficit.
    E.g. 'Only 20g protein logged — add moong dal or dahi.'
    E.g. 'Bloating today — swap rice with fruit salad to reduce bloating'
    E.g. 'Cramps today — swap rice for ragi to reduce inflammation.'
    E.g. 'No strength training in 7 days — add a 20-min session.'
    """)
    var sentence: String

    @Guide(description: "One word only: nutrition | exercise | symptoms")
    var category: String

    /// The measurable type that auto-completion tracks. One of: protein | workoutMinutes | steps | symptom | manual.
    @Guide(description: "One of: protein | workoutMinutes | steps | symptom | manual. Match the goal type.")
    var targetType: String

    /// The numeric value that must be reached to mark this goal complete.
    @Guide(description: "The total target value in appropriate units (grams for protein, minutes for workout, count for steps). Use 0 for symptom/manual goals.")
    var targetValue: Double

    /// The user's current progress at generation time.
    @Guide(description: "The user's current value from context (e.g. protein already logged today). Use 0 if not applicable.")
    var currentValue: Double

    /// The completion logic. One of: current>=target | any | manual.
    @Guide(description: "One of: current>=target | any | manual. Use 'current>=target' for measurable goals, 'any' for symptom goals, 'manual' for self-reported goals.")
    var completionRule: String

    /// Short celebratory message shown when the goal is completed.
    @Guide(description: "Short celebration message shown on completion. E.g. 'Protein goal achieved!', 'Great workout!', 'Symptom relief logged!' — max 6 words.")
    var celebrationMessage: String
}

// MARK: - Standardized Provider Metadata (Milestone 5A)

///
/// Standardized provider metadata.
///
/// Why this exists:
/// Enables analytics and UI transparency regarding which AI model generated the response.
///
struct ProviderMetadata: Codable {
    let name: String
    let modelId: String
}

///
/// Provider-neutral response wrapper.
///
/// Why this exists:
/// Ensures every AI engine (Foundation or Cloud) returns identical, standardized metadata
/// alongside the actual text or structured JSON output. `T` is not constrained to `Codable`
/// so this wrapper works for `@Generable` Foundation model types as well as plain `String`.
/// `AIBrain.routeRequest` wraps every result here to capture latency and provider name,
/// then returns `.content` so callers (ViewControllers) are completely unaffected.
///
struct AIResponse<T> {
    let content: T
    let providerMetadata: ProviderMetadata
    let timestamp: Date
    let latencyMS: Int?
}

