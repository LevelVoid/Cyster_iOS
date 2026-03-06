//
//  DailyActivityDataStore.swift
//  PCOS_App
//
//  Created by SDC-USER on 23/01/26.
//

import Foundation

class DailyActivityDataStore {
    static let shared = DailyActivityDataStore()
    
    private let userDefaults = UserDefaults.standard
    private let key = "dailyActivities"
    
    private init() {
        // Load sample data on first launch
        if loadAll().isEmpty {
            populateSampleData()
        }
    }
    
    // MARK: - CRUD Operations
    
    func loadAll() -> [DailyActivity] {
        guard let data = userDefaults.data(forKey: key),
              let activities = try? JSONDecoder().decode([DailyActivity].self, from: data) else {
            return []
        }
        return activities.sorted { $0.date > $1.date }
    }
    
    func save(_ activity: DailyActivity) {
        var activities = loadAll()
        
        // Remove existing entry for same date
        let calendar = Calendar.current
        activities.removeAll { calendar.isDate($0.date, inSameDayAs: activity.date) }
        
        // Add new entry
        activities.append(activity)
        
        // Save
        if let data = try? JSONEncoder().encode(activities) {
            userDefaults.set(data, forKey: key)
        }
    }
    
    func getActivity(for date: Date) -> DailyActivity? {
        let calendar = Calendar.current
        return loadAll().first { calendar.isDate($0.date, inSameDayAs: date) }
    }
    
    func updateOrCreateActivity(for date: Date, steps: Int? = nil, calories: Int? = nil, duration: Int? = nil) {
        var activity = getActivity(for: date) ?? DailyActivity(date: date)
        
        if let steps = steps {
            activity.steps += steps
        }
        if let calories = calories {
            activity.caloriesBurned += calories
        }
        if let duration = duration {
            activity.activeDurationSeconds += duration
        }
        
        save(activity)
    }
    
    // MARK: - Sample Data
    
    private func populateSampleData() {
        let calendar = Calendar.current
        let today = Date()
        
        // Generate data for last 60 days
        for dayOffset in 0..<60 {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
            
            // Vary the data to make it realistic
            let variance = Double.random(in: 0.7...1.3)
            
            let steps = Int(Double.random(in: 3000...10000) * variance)
            let calories = Int(Double.random(in: 150...450) * variance)
            let duration = Int(Double.random(in: 1800...5400) * variance) // 30-90 min
            
            let activity = DailyActivity(
                date: date,
                steps: steps,
                caloriesBurned: calories,
                activeDurationSeconds: duration
            )
            
            save(activity)
        }
        
        print("✅ Populated \(loadAll().count) days of sample activity data")
    }
    
    // MARK: - Sync with Workouts

    /// Syncs a completed workout session into the daily activity.
    /// Session calories (from HealthKit window / Keytel estimate) are stored in caloriesBurned.
    func syncWorkout(_ workout: CompletedWorkout) {
        let calendar = Calendar.current
        let workoutDate = calendar.startOfDay(for: workout.date)

        var activity = getActivity(for: workoutDate) ?? DailyActivity(date: workoutDate)

        // Accumulate session duration
        activity.activeDurationSeconds += workout.durationSeconds

        // Store session calories (best estimate stored on CompletedWorkout)
        let sessionCals = Int(workout.caloriesBurned)
        if sessionCals > 0 {
            activity.caloriesBurned = sessionCals
        } else {
            // Fallback if calories weren't set: use duration estimate (~6 cal/min)
            let minutes = Double(workout.durationSeconds) / 60.0
            activity.caloriesBurned = Int(minutes * 6.0)
        }

        save(activity)
    }

    /// Merges real HealthKit steps into today's activity AND stores total daily HealthKit calories
    /// separately so MetricsViewController can combine session + background HealthKit calories.
    func mergeHealthKitData(date: Date = Date(), steps: Int, healthKitDailyCalories: Int) {
        let calendar = Calendar.current
        let targetDate = calendar.startOfDay(for: date)
        var activity = getActivity(for: targetDate) ?? DailyActivity(date: targetDate)

        // Replace estimated step values with real HealthKit data
        if steps > 0 { activity.steps = steps }

        // Store the HealthKit all-day calories so metrics graph can combine it with session cals
        if healthKitDailyCalories > 0 { activity.healthKitCalories = healthKitDailyCalories }

        save(activity)
    }

    func clearAll() {
        userDefaults.removeObject(forKey: key)
    }
}

