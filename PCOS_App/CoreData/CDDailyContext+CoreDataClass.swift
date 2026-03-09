import Foundation
import CoreData

@objc(CDDailyContext)
public class CDDailyContext: NSManagedObject {
    
    /// Total calories for the day: session cals + background Apple Health cals.
    var totalCalories: Int {
        if healthKitCalories > 0 {
            return Int(healthKitCalories + caloriesBurned)
        }
        return Int(caloriesBurned)
    }
    
    /// Bridge to the DailyActivity struct used by SwiftUI Charts in MetricsViewController
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
