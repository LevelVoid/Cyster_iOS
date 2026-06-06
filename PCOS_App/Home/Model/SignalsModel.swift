import Foundation

struct PCOSSignal: Codable {
    let symptomName: String
    let signalTitle: String
    let signalIllustration: String

    let infoHeading: String
    let scientificReasons: [String]

    let appearanceHeading: String
    let appearanceDescriptions: [String]
    let doctorDisclaimer: String

    let supportHeading: String
    let supportActions: [SupportAction]
}

struct SupportAction: Codable {
    let category: SupportCategory
    let text: String
}
enum SupportCategory: String, Codable {
    case dietNutrition
    case physicalCare     
    case miscellaneous
}
struct SupportCategoryAssets {
    static let dietNutritionImage = "diet_nutrition_illustration"
    static let physicalCareImage = "skincare_exercise_illustration"
    static let miscellaneousImage = "sleep_misc_illustration"
}

enum DisplaySignal {
    case symptom(PCOSSignal, SymptomItem?)
    case phase(PhaseSignal, PhaseCardType)
}

