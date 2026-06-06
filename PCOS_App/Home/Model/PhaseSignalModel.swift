import Foundation

struct PhaseSignal: Codable {
    let phase: Phase
    let illustration: String
    let cards: [PhaseCardType]
    let understanding: PhaseUnderstanding
    let symptoms: PhaseSymptoms
    let support: PhaseSupport
}

struct PhaseUnderstanding: Codable {
    let heading: String
    let descriptions: [String]
}

struct PhaseSymptoms: Codable {
    let heading: String
    let introText: String
    let symptomItems: [SymptomItem]
}

struct PhaseSupport: Codable {
    let heading: String
    let actions: [SupportAction]
}
enum PhaseCardType : String, Codable{
    case understanding
    case symptoms
    case support
}
