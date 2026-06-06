import Foundation
import CoreData

@objc(CDCustomFood)
public class CDCustomFood: NSManagedObject {

    var ingredients: [Ingredient]? {
        get {
            guard let data = ingredientsData else { return nil }
            return try? JSONDecoder().decode([Ingredient].self, from: data)
        }
        set {
            ingredientsData = try? JSONEncoder().encode(newValue)
        }
    }

    func toFood() -> Food {
        Food(
            id: UUID(),  
            name: name ?? "Unknown",
            image: image,
            timeStamp: Date(),
            servingSize: servingSize,
            proteinContent: protein,
            carbsContent: carbs,
            fatsContent: fat,
            customCalories: calories > 0 ? Double(calories) : nil,
            ingredients: ingredients
        )
    }

    @discardableResult
    static func from(_ food: Food, isAI: Bool, context: NSManagedObjectContext) -> CDCustomFood {
        let cd = CDCustomFood(context: context)
        cd.id = UUID()
        cd.name = food.name
        cd.image = food.image
        cd.calories = Int32(food.calories)
        cd.servingSize = food.servingSize
        cd.unit = "g"
        cd.protein = food.proteinContent
        cd.carbs = food.carbsContent
        cd.fat = food.fatsContent
        cd.fiber = 0
        cd.isAIScanned = isAI
        cd.ingredients = food.ingredients
        cd.createdAt = Date()
        cd.timesUsed = 0
        return cd
    }
}
