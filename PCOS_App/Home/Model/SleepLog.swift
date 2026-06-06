import Foundation

enum SleepRating: Int, CaseIterable, Codable {
    case deep = 4
    case normal = 3
    case light = 2
    case disturbed = 1

    var title: String {
        switch self {
        case .deep: return "Deep Sleep"
        case .normal: return "Normal Sleep"
        case .light: return "Light Sleep"
        case .disturbed: return "Disturbed Sleep"
        }
    }
}

struct SleepLog: Codable {
    let sleepTime: Date
    let wakeTime: Date
    let rating: SleepRating

    var totalDuration: TimeInterval {
        var wake = wakeTime

        if wake < sleepTime {
            wake = Calendar.current.date(byAdding: .day, value: 1, to: wake) ?? wake
        }
        return wake.timeIntervalSince(sleepTime)
    }

    var hours: Int {
        return Int(totalDuration / 3600)
    }

    var minutes: Int {
        return Int(totalDuration.truncatingRemainder(dividingBy: 3600) / 60)
    }

    var displayString: String {
        return "\(hours)h \(String(format: "%02d", minutes))m"
    }
}
