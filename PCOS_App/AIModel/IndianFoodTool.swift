import Foundation
import NaturalLanguage
import FoundationModels

struct IndianFoodTool: Tool {

    var name: String { "search_indian_foods" }
    var description: String {
        """
        Search for specific Indian foods and their nutritional impact on PCOS. \
        Use this to find low-GI alternatives, protein-rich Indian meals, or \
        anti-inflammatory ingredients like haldi, alsi, and amla.
        """
    }

    typealias Output = String

    @Generable
    struct Arguments {
        @Guide(description: "The food item or category to search for, e.g., 'low GI grains', 'protein rich snacks', 'dal types'.")
        var query: String

        @Guide(description: "Optional: the focus goal, e.g., 'high protein', 'anti-inflammatory', 'gut health'.")
        var focus: String?
    }

    func call(arguments: Arguments) async throws -> String {
        let focusStr = arguments.focus.map { " with focus on \($0)" } ?? ""
        return """
        Indian PCOS-friendly foods for '\(arguments.query)'\(focusStr):
        • Moong Dal Chilla — High protein (12g), Low-GI, gut-friendly
        • Ragi Roti — High fibre, low-GI, insulin-balancing
        • Dahi with ground Alsi (flaxseed) — Probiotic + omega-3, DHT-reducing
        • Palak Dal — Iron + protein, anti-inflammatory
        • Rajma — Low-GI (GI 28), high inositol, hormone-supportive
        """
    }
}
