//
//  SleepLog.swift
//  PCOS_App
//
//  Created by SDC-USER on 05/03/26.
//

import Foundation

// MARK: - SleepRating Enum
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

// MARK: - SleepLog Model
struct SleepLog: Codable {
    let sleepTime: Date
    let wakeTime: Date
    let rating: SleepRating

    /// Total sleep duration in seconds
    var totalDuration: TimeInterval {
        var wake = wakeTime
        // If wake time is before sleep time, it's the next day
        if wake < sleepTime {
            wake = Calendar.current.date(byAdding: .day, value: 1, to: wake) ?? wake
        }
        return wake.timeIntervalSince(sleepTime)
    }

    /// Total hours (whole number)
    var hours: Int {
        return Int(totalDuration / 3600)
    }

    /// Remaining minutes after whole hours
    var minutes: Int {
        return Int(totalDuration.truncatingRemainder(dividingBy: 3600) / 60)
    }

    /// Human-readable display string, e.g. "7h 05m"
    var displayString: String {
        return "\(hours)h \(String(format: "%02d", minutes))m"
    }
}
