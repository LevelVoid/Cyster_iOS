import Foundation
import UIKit
import CoreData

class SleepDataStore {

    static let shared = SleepDataStore()
    private init() {}

    private func key(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return "sleepLog_\(formatter.string(from: date))"
    }

    private var todayKey: String { key(for: Date()) }

    func saveSleepLog(_ log: SleepLog) {

        if let encoded = try? JSONEncoder().encode(log) {
            UserDefaults.standard.set(encoded, forKey: key(for: log.wakeTime))
        }

        let dailyContext = DailyActivityDataStore.shared.getOrCreateContext(for: log.wakeTime)
        dailyContext.sleepTime = log.sleepTime
        dailyContext.wakeTime = log.wakeTime

        let qualityScore: Double
        switch log.rating {
        case .deep:      qualityScore = 1.0
        case .normal:    qualityScore = 0.75
        case .light:     qualityScore = 0.5
        case .disturbed: qualityScore = 0.25
        }
        dailyContext.sleepQuality = qualityScore

        let ctx = (UIApplication.shared.delegate as! AppDelegate).viewContext
        if ctx.hasChanges {
            try? ctx.save()
        }

        print("✅ SleepLog saved to UserDefaults + CDDailyContext")
    }

    func loadTodaySleepLog() -> SleepLog? {
        guard let data = UserDefaults.standard.data(forKey: todayKey),
              let log = try? JSONDecoder().decode(SleepLog.self, from: data) else {
            return nil
        }
        return log
    }

    func loadSleepLog(for date: Date) -> SleepLog? {
        guard let data = UserDefaults.standard.data(forKey: key(for: date)),
              let log = try? JSONDecoder().decode(SleepLog.self, from: data) else {
            return nil
        }
        return log
    }
}
