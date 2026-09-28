import Foundation

struct DailyGoal: Codable {
    let id: String
    let title: String
    let sentence: String
    let category: String

    let targetType: String
    let targetValue: Double

    var currentValue: Double
    var isCompleted: Bool

    let completionRule: String
    let celebrationMessage: String
    let generatedReason: String
}
