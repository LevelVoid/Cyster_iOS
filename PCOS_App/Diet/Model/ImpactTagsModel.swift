import Foundation

enum ImpactTags: String, Codable, CaseIterable {

    case bloatingTrigger
    case bloatingReducer
    case crampTrigger
    case crampReducer
    case periodPainTrigger
    case periodPainReducer

    case estrogenBoosting
    case estrogenLowering
    case progesteroneSupporting
    case pcosFriendly
    case pcosTrigger
    case androgenBoosting
    case androgenLowering
    case dairySensitive
    case glutenSensitive
    case soySensitive

    case insulinSpiking
    case insulinBalancing
    case highInsulinLoad
    case lowInsulinLoad
    case highGlycemic
    case mediumGlycemic
    case lowGlycemic

    case highProtein
    case lowProtein
    case highFibre
    case lowFibre
    case healthyFats
    case unhealthyFats
    case highCarb
    case lowCarb

    case antiInflammatory
    case proInflammatory

    case moodBoost
    case energyBoost

    case processed
    case ultraProcessed
    case wholeFood

    case sugary
    case artificialSweetener
    case noAddedSugar

    case caffeine
    case chocolate

    case gasForming
    case gutFriendly
    case none

    private static let backendAliases: [String: ImpactTags] = [
        "low-gi": .lowGlycemic,
        "high-gi": .highGlycemic,
        "medium-gi": .mediumGlycemic,
        "anti-inflammatory": .antiInflammatory,
        "high-protein": .highProtein,
        "high-fiber": .highFibre,
        "high-fibre": .highFibre,
        "low-fiber": .lowFibre,
        "low-fibre": .lowFibre,
        "whole-grain": .wholeFood,
        "whole-food": .wholeFood,
        "probiotic": .gutFriendly,
        "gut-friendly": .gutFriendly,
        "healthy-fats": .healthyFats,
        "low-carb": .lowCarb,
        "high-carb": .highCarb,
        "processed": .processed,
        "pcos-friendly": .pcosFriendly,
    ]

    init(from decoder: Decoder) throws {
        let value = try decoder.singleValueContainer().decode(String.self)
        if let tag = ImpactTags(rawValue: value) {
            self = tag
        } else if let tag = ImpactTags.backendAliases[value] {
            self = tag
        } else {
            self = .none
        }
    }
}
