//
//  HealthKitManager.swift
//  PCOS_App
//
//  Created by PCOS_App on 06/03/26.
//

import Foundation
import HealthKit

final class HealthKitManager {

    static let shared = HealthKitManager()
    private let store = HKHealthStore()

    private init() {}

    // MARK: - HealthKit Types

    private let readTypes: Set<HKObjectType> = {
        var types = Set<HKObjectType>()
        if let steps = HKObjectType.quantityType(forIdentifier: .stepCount) { types.insert(steps) }
        if let activeCal = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) { types.insert(activeCal) }
        if let hr = HKObjectType.quantityType(forIdentifier: .heartRate) { types.insert(hr) }
        if let sleep = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) { types.insert(sleep) }
        return types
    }()

    private let writeTypes: Set<HKSampleType> = {
        var types = Set<HKSampleType>()
        if let activeCal = HKSampleType.quantityType(forIdentifier: .activeEnergyBurned) { types.insert(activeCal) }
        return types
    }()

    // MARK: - Authorization

    /// Request HealthKit authorization. Call once at app launch or before first use.
    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(false, nil)
            return
        }
        store.requestAuthorization(toShare: writeTypes, read: readTypes, completion: completion)
    }

    // MARK: - Steps

    /// Fetches today's total step count from HealthKit.
    func fetchTodaySteps(completion: @escaping (Int) -> Void) {
        guard let stepType = HKObjectType.quantityType(forIdentifier: .stepCount) else {
            completion(0); return
        }
        let predicate = todayPredicate()
        let query = HKStatisticsQuery(
            quantityType: stepType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { _, result, _ in
            let steps = result?.sumQuantity()?.doubleValue(for: HKUnit.count()) ?? 0
            completion(Int(steps))
        }
        store.execute(query)
    }

    /// Fetches per-day step counts from HealthKit over a date range.
    /// Returns a dictionary keyed by start-of-day Date → step count.
    func fetchDailySteps(from start: Date, to end: Date, completion: @escaping ([Date: Int]) -> Void) {
        guard let stepType = HKObjectType.quantityType(forIdentifier: .stepCount) else {
            completion([:]); return
        }
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        let interval = DateComponents(day: 1)
        let anchor = Calendar.current.startOfDay(for: start)

        let query = HKStatisticsCollectionQuery(
            quantityType: stepType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum,
            anchorDate: anchor,
            intervalComponents: interval
        )
        query.initialResultsHandler = { _, results, _ in
            var stepsByDay: [Date: Int] = [:]
            results?.enumerateStatistics(from: start, to: end) { statistics, _ in
                let day = Calendar.current.startOfDay(for: statistics.startDate)
                let steps = Int(statistics.sumQuantity()?.doubleValue(for: .count()) ?? 0)
                if steps > 0 { stepsByDay[day] = steps }
            }
            completion(stepsByDay)
        }
        store.execute(query)
    }

    // MARK: - Active Calories

    /// Fetches today's total active calories burned from HealthKit (Apple Watch / Fitness app).
    func fetchTodayActiveCalories(completion: @escaping (Double) -> Void) {
        guard let calType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) else {
            completion(0); return
        }
        let predicate = todayPredicate()
        let query = HKStatisticsQuery(
            quantityType: calType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { _, result, _ in
            let cals = result?.sumQuantity()?.doubleValue(for: HKUnit.kilocalorie()) ?? 0
            completion(cals)
        }
        store.execute(query)
    }

    /// Fetches per-day active calories from HealthKit over a date range.
    /// Returns a dictionary keyed by start-of-day Date → kilocalories.
    func fetchDailyActiveCalories(from start: Date, to end: Date, completion: @escaping ([Date: Double]) -> Void) {
        guard let calType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) else {
            completion([:]); return
        }
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: [])
        let interval = DateComponents(day: 1)
        let anchor = Calendar.current.startOfDay(for: start)

        let query = HKStatisticsCollectionQuery(
            quantityType: calType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum,
            anchorDate: anchor,
            intervalComponents: interval
        )
        query.initialResultsHandler = { _, results, _ in
            var calsByDay: [Date: Double] = [:]
            results?.enumerateStatistics(from: start, to: end) { statistics, _ in
                let day = Calendar.current.startOfDay(for: statistics.startDate)
                let cals = statistics.sumQuantity()?.doubleValue(for: HKUnit.kilocalorie()) ?? 0
                if cals > 0 { calsByDay[day] = cals }
            }
            completion(calsByDay)
        }
        store.execute(query)
    }

    // MARK: - Active Calories (time-windowed)

    /// Fetches active calories burned within a specific time window (e.g. a single workout session).
    /// Uses no strict option so Apple Watch batch-writes that overlap the boundary are included.
    func fetchActiveCalories(from start: Date, to end: Date, completion: @escaping (Double) -> Void) {
        guard let calType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) else {
            completion(0); return
        }
        // No strict option — include any sample that overlaps the window (handles Watch batch writes)
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: [])
        let query = HKStatisticsQuery(
            quantityType: calType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { _, result, _ in
            let cals = result?.sumQuantity()?.doubleValue(for: HKUnit.kilocalorie()) ?? 0
            completion(cals)
        }
        store.execute(query)
    }

    // MARK: - Heart Rate

    /// Fetches average heart rate for a workout session using a two-pass strategy:
    /// Pass 1 — exact session window (most accurate, uses real exercise HR)
    /// Pass 2 — ±5 min expanded window (fallback for passive Watch sampling cadence)
    /// Returns nil only when both passes find no data.
    func fetchHeartRate(from start: Date, to end: Date, completion: @escaping (Double?) -> Void) {
        guard let hrType = HKObjectType.quantityType(forIdentifier: .heartRate) else {
            completion(nil); return
        }

        // PASS 1: exact session window
        let exactPredicate = HKQuery.predicateForSamples(withStart: start, end: end, options: [])
        let exactQuery = HKSampleQuery(
            sampleType: hrType,
            predicate: exactPredicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: nil
        ) { [weak self] _, samples, _ in
            guard let self = self else { return }
            if let samples = samples as? [HKQuantitySample], !samples.isEmpty {
                // ✅ Real session HR found — use it
                let avg = samples.reduce(0.0) { $0 + $1.quantity.doubleValue(for: HKUnit(from: "count/min")) }
                    / Double(samples.count)
                completion(avg)
            } else {
                // PASS 2: expand ±5 min (handles passive Watch sampling cadence)
                let expandedStart = start.addingTimeInterval(-5 * 60)
                let expandedEnd   = end.addingTimeInterval(5 * 60)
                let expandedPredicate = HKQuery.predicateForSamples(withStart: expandedStart, end: expandedEnd, options: [])
                let expandedQuery = HKSampleQuery(
                    sampleType: hrType,
                    predicate: expandedPredicate,
                    limit: HKObjectQueryNoLimit,
                    sortDescriptors: nil
                ) { _, expandedSamples, _ in
                    guard let expandedSamples = expandedSamples as? [HKQuantitySample],
                          !expandedSamples.isEmpty else {
                        completion(nil); return
                    }
                    let avg = expandedSamples.reduce(0.0) { $0 + $1.quantity.doubleValue(for: HKUnit(from: "count/min")) }
                        / Double(expandedSamples.count)
                    completion(avg)
                }
                self.store.execute(expandedQuery)
            }
        }
        store.execute(exactQuery)
    }


    // MARK: - Keytel Heart-Rate Calorie Formula

    /// Estimates calories burned using the Keytel et al. gender-specific formula.
    /// - Parameters:
    ///   - avgHR: Average heart rate in bpm
    ///   - ageYears: User age in years
    ///   - weightKg: User weight in kilograms
    ///   - durationMin: Workout duration in minutes
    ///   - isFemale: true for female, false for male
    /// - Returns: Estimated kilocalories burned
    func estimateCaloriesFromHeartRate(
        avgHR: Double,
        ageYears: Int,
        weightKg: Double,
        durationMin: Double,
        isFemale: Bool = true
    ) -> Double {
        // Keytel (2005) formula
        // Female: (-20.4022 + 0.4472×HR − 0.1263×W + 0.074×A) / 4.184 × T
        // Male:   (-55.0969 + 0.6309×HR − 0.1988×W + 0.2017×A) / 4.184 × T
        let age = Double(ageYears)
        let calPerMin: Double
        if isFemale {
            calPerMin = (-20.4022 + 0.4472 * avgHR - 0.1263 * weightKg + 0.074 * age) / 4.184
        } else {
            calPerMin = (-55.0969 + 0.6309 * avgHR - 0.1988 * weightKg + 0.2017 * age) / 4.184
        }
        return max(0, calPerMin * durationMin)
    }

    // MARK: - Sleep Analysis

    /// Fetches last night's sleep data from HealthKit (covers 8 PM yesterday → now).
    func fetchSleepLastNight(completion: @escaping (SleepData?) -> Void) {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            completion(nil); return
        }
        let calendar = Calendar.current
        let now = Date()
        // Look back 24 hours for sleep samples
        guard let start = calendar.date(byAdding: .hour, value: -24, to: now) else {
            completion(nil); return
        }
        let predicate = HKQuery.predicateForSamples(withStart: start, end: now, options: .strictStartDate)
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        let query = HKSampleQuery(
            sampleType: sleepType,
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: [sort]
        ) { _, samples, _ in
            guard let samples = samples as? [HKCategorySample], !samples.isEmpty else {
                completion(nil); return
            }
            let asleepValues: Set<Int> = [
                HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue,
                HKCategoryValueSleepAnalysis.asleepCore.rawValue,
                HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
                HKCategoryValueSleepAnalysis.asleepREM.rawValue
            ]
            var asleepSeconds = 0.0
            var inBedSeconds = 0.0
            for sample in samples {
                let duration = sample.endDate.timeIntervalSince(sample.startDate)
                if asleepValues.contains(sample.value) {
                    asleepSeconds += duration
                }
                if sample.value == HKCategoryValueSleepAnalysis.inBed.rawValue {
                    inBedSeconds += duration
                }
            }
            let totalAsleepMin = Int(asleepSeconds / 60)
            let totalInBedMin  = Int(inBedSeconds / 60)
            let totalHours     = asleepSeconds / 3600.0
            let quality        = SleepQuality(hours: totalHours)
            let sleepData      = SleepData(
                totalHours: totalHours,
                inBedMinutes: totalInBedMin,
                asleepMinutes: totalAsleepMin,
                quality: quality
            )
            completion(sleepData)
        }
        store.execute(query)
    }

    // MARK: - Helpers
    
    /// Fetches per-day sleep durations from HealthKit over a date range.
    func fetchDailySleep(from startDate: Date, to endDate: Date, completion: @escaping ([Date: Double]) -> Void) {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            completion([:])
            return
        }

        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictEndDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: true)

        let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { _, samples, _ in
            guard let sleepSamples = samples as? [HKCategorySample] else {
                DispatchQueue.main.async { completion([:]) }
                return
            }

            var dailySleep: [Date: Double] = [:]
            let calendar = Calendar.current
            
            let asleepValues: Set<Int> = [
                HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue,
                HKCategoryValueSleepAnalysis.asleepCore.rawValue,
                HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
                HKCategoryValueSleepAnalysis.asleepREM.rawValue
            ]

            for sample in sleepSamples {
                if asleepValues.contains(sample.value) {
                    let duration = sample.endDate.timeIntervalSince(sample.startDate)
                    let hours = duration / 3600.0
                    
                    // Group by start of day of the sample's end date (wake up day)
                    let dayDate = calendar.startOfDay(for: sample.endDate)
                    dailySleep[dayDate, default: 0.0] += hours
                }
            }

            DispatchQueue.main.async {
                completion(dailySleep)
            }
        }
        store.execute(query)
    }

    private func todayPredicate() -> NSPredicate {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        return HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)
    }
}

// MARK: - User Profile Helper (reads from UserDefaults set during onboarding)

extension HealthKitManager {
    /// Returns the user's age in years from onboarding data, defaulting to 27.
    var userAge: Int {
        let dob = UserDefaults.standard.object(forKey: "userDOB") as? Date
        guard let dob = dob else { return 27 }
        return Calendar.current.dateComponents([.year], from: dob, to: Date()).year ?? 27
    }

    /// Returns the user's weight in kg from onboarding data, defaulting to 60.
    var userWeightKg: Double {
        let weight = UserDefaults.standard.double(forKey: "userWeightKg")
        return weight > 0 ? weight : 60.0
    }
}
