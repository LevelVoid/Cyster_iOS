import Foundation
import CoreData

@objc(CDFoodTag)
public class CDFoodTag: NSManagedObject {

    var impactTag: ImpactTags? {
        guard let name = tagName else { return nil }
        return ImpactTags(rawValue: name)
    }

    static func computeTags(
        protein: Double,
        carbs: Double,
        fats: Double,
        fiber: Double,
        calories: Double,
        servingGrams: Double
    ) -> [String] {
        var tags: [String] = []

        if calories > 0 {
            let proteinEnergyPct = (protein * 4.0 / calories) * 100.0
            if proteinEnergyPct >= 20.0 {
                tags.append(ImpactTags.highProtein.rawValue)
            } else if proteinEnergyPct < 10.0 {
                tags.append(ImpactTags.lowProtein.rawValue)
            }
        }

        if calories > 0 {
            let carbEnergyPct = (carbs * 4.0 / calories) * 100.0
            if carbEnergyPct > 60.0 {
                tags.append(ImpactTags.highCarb.rawValue)
            } else if carbEnergyPct < 40.0 {
                tags.append(ImpactTags.lowCarb.rawValue)
            }
        }

        if servingGrams > 0 {
            let fiberPer100g = (fiber / servingGrams) * 100.0
            if fiberPer100g >= 6.0 {
                tags.append(ImpactTags.highFibre.rawValue)
            } else if fiberPer100g < 3.0 {
                tags.append(ImpactTags.lowFibre.rawValue)
            }
        }

        if fats >= 15.0 {
            tags.append(ImpactTags.healthyFats.rawValue)
        } else if fats < 3.0 && calories > 0 {

        }

        return tags
    }

    static func saveTags(
        for cdFoodLog: CDFoodLog,
        staticTags: [ImpactTags]?,
        context: NSManagedObjectContext
    ) {

        if let existing = cdFoodLog.foodTags as? Set<CDFoodTag> {
            let oldComputed = existing.filter { $0.isComputed }
            for tag in oldComputed {
                context.delete(tag)
            }
        }

        if let staticTags = staticTags {
            for tag in staticTags where tag != .none {
                let cdTag = CDFoodTag(context: context)
                cdTag.id = UUID()
                cdTag.tagName = tag.rawValue
                cdTag.isComputed = false
                cdTag.foodLog = cdFoodLog
            }
        }

        let calories: Double
        if cdFoodLog.customCalories > 0 {
            calories = cdFoodLog.customCalories
        } else {
            calories = (cdFoodLog.proteinContent * 4) +
                       (cdFoodLog.carbsContent * 4) +
                       (cdFoodLog.fatsContent * 9)
        }

        let computedTags = computeTags(
            protein: cdFoodLog.proteinContent,
            carbs: cdFoodLog.carbsContent,
            fats: cdFoodLog.fatsContent,
            fiber: cdFoodLog.fiberContent,
            calories: calories,
            servingGrams: cdFoodLog.servingSize
        )

        for tagName in computedTags {

            if let staticTags = staticTags,
               staticTags.contains(where: { $0.rawValue == tagName }) {
                continue
            }
            let cdTag = CDFoodTag(context: context)
            cdTag.id = UUID()
            cdTag.tagName = tagName
            cdTag.isComputed = true
            cdTag.foodLog = cdFoodLog
        }
    }
}
