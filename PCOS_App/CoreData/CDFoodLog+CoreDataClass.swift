import Foundation
import CoreData

@objc(CDFoodLog)
public class CDFoodLog: NSManagedObject {

    var ingredients: [Ingredient]? {
        get {
            guard let data = ingredientsData else { return nil }
            return try? JSONDecoder().decode([Ingredient].self, from: data)
        }
        set {
            ingredientsData = try? JSONEncoder().encode(newValue)
        }
    }

    var tags: [ImpactTags]? {
        get {
            guard let data = tagsData else { return nil }
            return try? JSONDecoder().decode([ImpactTags].self, from: data)
        }
        set {
            tagsData = try? JSONEncoder().encode(newValue)
        }
    }

    func toFood() -> Food {
        return Food(
            id: id ?? UUID(),
            name: name ?? "Unknown",
            image: imageURL ?? localImage,
            timeStamp: timeStamp ?? Date(),
            servingSize: servingSize,
            weight: weight > 0 ? weight : nil,
            proteinContent: proteinContent,
            carbsContent: carbsContent,
            fatsContent: fatsContent,
            fiberContent: fiberContent,
            customCalories: customCalories > 0 ? customCalories : nil,
            tags: self.tags,
            ingredients: self.ingredients
        )
    }

    static func from(_ food: Food, context: NSManagedObjectContext) -> CDFoodLog {
        let cd = CDFoodLog(context: context)
        cd.id = food.id
        cd.name = food.name
        cd.timeStamp = food.timeStamp
        cd.servingSize = food.servingSize
        cd.weight = food.weight ?? 0
        cd.proteinContent = food.proteinContent
        cd.carbsContent = food.carbsContent
        cd.fatsContent = food.fatsContent
        cd.fiberContent = food.fiberContent
        cd.customCalories = food.customCalories ?? 0
        cd.desc = food.desc

        if let img = food.image {
            if img.hasPrefix("http") {
                cd.imageURL = img
                cd.localImage = nil
            } else {
                cd.localImage = img
                cd.imageURL = nil
            }
        }

        cd.ingredients = food.ingredients
        cd.tags = food.tags

        return cd
    }
}
