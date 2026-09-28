import Foundation

struct Food: Codable, Identifiable {
    let id: UUID
    var name: String
    var image: String?
    var timeStamp: Date
    var servingSize: Double
    var weight: Double?
    var desc: String = ""

    var proteinContent: Double
    var carbsContent: Double
    var fatsContent: Double
    var fiberContent: Double = 0

    var customCalories: Double?

    var tags: [ImpactTags]?

    var ingredients: [Ingredient]? = nil

    var confidence: Double? = nil

    var calories: Double {
        if let customCalories = customCalories {
            return customCalories
        }
        if let ingredients = ingredients {
            let total = ingredients.reduce(0) { $0 + ($1.calories ?? 0) }
            return total.rounded(toPlaces: 2)
        }
        let total = (proteinContent * 4) +
                    (carbsContent * 4) +
                    (fatsContent * 9)
        return total.rounded(toPlaces: 2)
    }

    init(id: UUID = UUID(), name: String, image: String? = nil, timeStamp: Date = Date(),
         servingSize: Double = 1.0, weight: Double? = nil, desc: String = "",
         proteinContent: Double = 0, carbsContent: Double = 0, fatsContent: Double = 0,
         fiberContent: Double = 0, customCalories: Double? = nil,
         tags: [ImpactTags]? = nil, ingredients: [Ingredient]? = nil,
         confidence: Double? = nil) {
        self.id = id
        self.name = name
        self.image = image
        self.timeStamp = timeStamp
        self.servingSize = servingSize
        self.weight = weight
        self.desc = desc
        self.proteinContent = proteinContent
        self.carbsContent = carbsContent
        self.fatsContent = fatsContent
        self.fiberContent = fiberContent
        self.customCalories = customCalories
        self.tags = tags
        self.ingredients = ingredients
        self.confidence = confidence
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)

        if let uuidString = try? c.decode(String.self, forKey: .id),
           let parsed = UUID(uuidString: uuidString) {
            id = parsed
        } else {
            id = (try? c.decode(UUID.self, forKey: .id)) ?? UUID()
        }

        name            = try c.decode(String.self, forKey: .name)
        image           = try c.decodeIfPresent(String.self, forKey: .image)
        timeStamp       = try c.decodeIfPresent(Date.self, forKey: .timeStamp) ?? Date()
        servingSize     = try c.decodeIfPresent(Double.self, forKey: .servingSize) ?? 1.0
        weight          = try c.decodeIfPresent(Double.self, forKey: .weight)
        desc            = try c.decodeIfPresent(String.self, forKey: .desc) ?? ""
        proteinContent  = try c.decodeIfPresent(Double.self, forKey: .proteinContent) ?? 0
        carbsContent    = try c.decodeIfPresent(Double.self, forKey: .carbsContent) ?? 0
        fatsContent     = try c.decodeIfPresent(Double.self, forKey: .fatsContent) ?? 0
        fiberContent    = try c.decodeIfPresent(Double.self, forKey: .fiberContent) ?? 0
        customCalories  = try c.decodeIfPresent(Double.self, forKey: .customCalories)
        tags            = try c.decodeIfPresent([ImpactTags].self, forKey: .tags)
        ingredients     = try c.decodeIfPresent([Ingredient].self, forKey: .ingredients)
        confidence      = try c.decodeIfPresent(Double.self, forKey: .confidence)
    }
}

struct OFFResponse: Codable, Sendable {
    let status: Int
    let code: String
    let product: OFFProduct?
}

struct OFFProduct: Codable, Sendable {
    let product_name: String?
    let image_url: String?
    let image_front_url: String?
    let image_small_url: String?
    let nutriments: OFFNutriments?
    let ingredients: [OFFIngredient]?

}

struct OFFNutriments: Codable, Sendable {
    let energyKcal100g: Double?
    let proteins100g: Double?
    let carbohydrates100g: Double?
    let fat100g: Double?
    let fiber100g: Double?

    enum CodingKeys: String, CodingKey {
        case energyKcal100g = "energy-kcal_100g"
        case proteins100g = "proteins_100g"
        case carbohydrates100g = "carbohydrates_100g"
        case fat100g = "fat_100g"
        case fiber100g = "fiber_100g"
    }
}

struct OFFIngredient: Codable, Sendable {
    let text: String?
}

extension OFFProduct{
    func toFood() -> Food {

            let nutr = nutriments

            let mappedIngredients: [Ingredient]? = ingredients?.compactMap { offIng in
                guard let name = offIng.text?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty else {
                    return nil
                }
                return Ingredient(
                    id: UUID(),
                    name: name,
                    quantity: 100,          
                    protein: 0,             
                    carbs: 0,
                    fats: 0,
                    fibre: 0,
                    tags: []                
                )
            }

            let food: Food = Food(
                id: UUID(),
                name: product_name ?? "Unknown Food",
                image: image_url ?? image_front_url ?? image_small_url,
                timeStamp: Date(),
                servingSize: 100,
                proteinContent: nutr?.proteins100g ?? 0,
                carbsContent: nutr?.carbohydrates100g ?? 0,
                fatsContent: nutr?.fat100g ?? 0,
                customCalories: nutr?.energyKcal100g,
                tags: [],
                ingredients: mappedIngredients,
            )
            return food
        }
}
