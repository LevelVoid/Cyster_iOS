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
}
