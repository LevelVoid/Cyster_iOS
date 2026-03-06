//
//  DailyActivity.swift
//  PCOS_App
//
//  Created by SDC-USER on 23/01/26.
//

import Foundation

struct DailyActivity: Codable {
    let date: Date
    var steps: Int
    /// Calories burned during in-app workout sessions only.
    var caloriesBurned: Int
    var activeDurationSeconds: Int
    /// All-day active calories from Apple Health / Apple Watch (background tracking).
    /// Combined with caloriesBurned for the metrics graph total.
    var healthKitCalories: Int

    init(date: Date, steps: Int = 0, caloriesBurned: Int = 0, activeDurationSeconds: Int = 0, healthKitCalories: Int = 0) {
        self.date = date
        self.steps = steps
        self.caloriesBurned = caloriesBurned
        self.activeDurationSeconds = activeDurationSeconds
        self.healthKitCalories = healthKitCalories
    }

    /// Total calories for the day: session cals + background Apple Health cals.
    var totalCalories: Int {
        // If we have HealthKit all-day calories, use them as the base (they may already include session burn).
        // We add session calories only when HealthKit returned 0 (no Watch / no permission).
        if healthKitCalories > 0 {
            return healthKitCalories + caloriesBurned
        }
        return caloriesBurned
    }
}
