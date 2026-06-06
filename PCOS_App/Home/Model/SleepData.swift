import Foundation

enum SleepQuality {
    case poor       
    case fair       
    case good       
    case excellent  

    init(hours: Double) {
        switch hours {
        case ..<5:   self = .poor
        case 5..<7:  self = .fair
        case 7..<9:  self = .good
        default:     self = .excellent
        }
    }

    var label: String {
        switch self {
        case .poor:      return "Poor"
        case .fair:      return "Fair"
        case .good:      return "Good"
        case .excellent: return "Excellent"
        }
    }

    var emoji: String {
        switch self {
        case .poor:      return "😴"
        case .fair:      return "😐"
        case .good:      return "😊"
        case .excellent: return "🌟"
        }
    }
}

struct SleepData {
    let totalHours: Double       
    let inBedMinutes: Int        
    let asleepMinutes: Int       
    let quality: SleepQuality

    var formattedDuration: String {
        let hours = Int(totalHours)
        let minutes = Int((totalHours - Double(hours)) * 60)
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}
