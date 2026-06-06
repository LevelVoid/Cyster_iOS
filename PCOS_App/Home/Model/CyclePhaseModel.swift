import Foundation
import UIKit

struct CycleData: Codable {
    let id: UUID
    let month: String
    let startDate: Date

    var endDate: Date?

    var isOvulationConfirmed: Bool = false

    var days: [CycleDay]
}

struct CycleDay: Codable {
    let dayIndex: Int

    var phase: Phase

    let symptoms: [SymptomItem]

    var basalBodyTemperature: Double?
}

enum Phase: Codable {
    case menstrual
    case follicular
    case ovulation
    case luteal
    case unknown
}

extension CycleData {

    var isComplete: Bool {
        endDate != nil
    }

    var cycleLength: Int {
        if let end = endDate {
            return max(
                Calendar.current.dateComponents([.day], from: startDate, to: end).day ?? days.count,
                days.count
            )
        }
        return days.count
    }

    var periodLength: Int {
        days.filter { $0.phase == .menstrual }.count
    }
}
extension Phase {

    var backgroundColor: UIColor {
            switch self {
            case .menstrual:

                return UIColor(hex: "FFB0B0")

            case .follicular:

                return UIColor(hex: "8CF4F2")

            case .ovulation:

                return UIColor(hex: "FFEFA2")

            case .luteal:

                return UIColor(hex: "DDBFFF")

            case .unknown:
                return UIColor.systemGray4
            }
        }

    var icon: UIImage? {
        switch self {
        case .ovulation:
            return UIImage(systemName: "sparkles")
        default:
            return nil
        }
    }

    var iconTint: UIColor {
        switch self {
        case .ovulation:
            return UIColor.systemOrange
        default:
            return .clear
        }
    }

    var displayName: String {
        switch self {
        case .menstrual:  return "Menstrual Phase"
        case .follicular: return "Follicular Phase"
        case .ovulation:  return "Ovulation Phase"
        case .luteal:     return "Luteal Phase"
        case .unknown:    return ""
        }
    }

    var quote: String {
        switch self {
        case .menstrual:
            return "Your body may be asking for rest and gentler movement today"
        case .follicular:
            return "Energy is building a great time to try something new"
        case .ovulation:
            return "You may feel more confident and energetic today"
        case .luteal:
            return "Be gentle with yourself your body is preparing for the next cycle"
        case .unknown:
            return "Track your cycle to get personalised insights"
        }
    }
}

