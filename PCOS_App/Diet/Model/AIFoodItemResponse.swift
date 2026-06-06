import Foundation

struct AIIngredient: Codable {
    let name: String
    let quantity: Double
    let unit: String
    let protein: Double
    let carbs: Double
    let fats: Double
    let fibre: Double
}

struct AIFoodResponse: Codable {
    let name: String
    let calories: Int
    let servingSize: Double
    let unit: String
    let protein: Double
    let carbs: Double
    let fat: Double
    let desc: String
    let ingredients: [AIIngredient]
}
