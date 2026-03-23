//
//  AIOutputTypes.swift
//  PCOS_App
//
//  Created by SDC-USER on 23/03/26.
//

import Foundation
import FoundationModels

@Generable
struct MealRecommendationOutput {
    @Guide(description: "One factual sentence with specific numbers, explaining why these foods were chosen based on recent logs.")
    var observationLine: String

    @Guide(description: "A short 2-4 word focus tag for the UI element, e.g. 'Low on protein', 'Cramp recovery'.")
    var focusTag: String

    @Guide(description: "Exactly 3 Indian food suggestions.")
    var foods: [FoodCard]
}

@Generable
struct FoodCard {
    @Guide(description: "Specific name of the dish, including Hindi name if applicable, e.g., 'Dahi with ground flaxseed (Alsi)'.")
    var name: String

    @Guide(description: "The most relevant macro or health metric, e.g., '22g protein', 'Low-GI (GI 38)'.")
    var primaryMacro: String

    @Guide(description: "Exactly 2 impact tags from the fixed PCOS list.")
    var impactTags: [String]

    @Guide(description: "One word hint for the UI color: pink, green, or amber.")
    var colorHint: String
}

@Generable
struct DailyGoalsOutput {
    @Guide(description: "Exactly 2 actionable goals derived from cross-day pattern analysis.")
    var goals: [GoalCard]
}

@Generable
struct GoalCard {
    @Guide(description: "One actionable sentence starting with a verb, with evidence from logs, e.g., 'Sleep by 10pm tonight — your average this week is 5.8h'.")
    var sentence: String

    @Guide(description: "The goal category: nutrition, sleep, exercise, or symptoms.")
    var category: String
}
