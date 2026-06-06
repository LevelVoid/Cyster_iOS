import SwiftUI

enum MacroType {
    case protein
    case carbs
    case fats

    var title: String {
        switch self {
        case .protein: return "Protein Intake"
        case .carbs: return "Carbohydrate Intake"
        case .fats: return "Fat Intake"
        }
    }

    var color: Color {
        switch self {
        case .protein: return .green
        case .carbs: return .orange
        case .fats: return .indigo
        }
    }

    var unit: String { return "g" }
}

enum MacroChartTimeRange: Int {
    case day = 0
    case week = 1
    case month = 2
    case year = 3
}

struct MacroChartDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
    let label: String
}
