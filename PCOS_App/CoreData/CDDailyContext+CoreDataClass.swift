import Foundation
import CoreData

@objc(CDDailyContext)
public class CDDailyContext: NSManagedObject {

    var totalCalories: Int {
        if healthKitCalories > 0 {
            return Int(healthKitCalories + caloriesBurned)
        }
        return Int(caloriesBurned)
    }

    var sleepHours: Double? {
        guard let sleep = sleepTime, let wake = wakeTime else { return nil }
        return wake.timeIntervalSince(sleep) / 3600.0
    }

    func toDailyActivity() -> DailyActivity {
        DailyActivity(
            date: date ?? Date(),
            steps: Int(steps),
            caloriesBurned: Int(caloriesBurned),
            activeDurationSeconds: Int(activeDurationSeconds),
            healthKitCalories: Int(healthKitCalories)
        )
    }
}
