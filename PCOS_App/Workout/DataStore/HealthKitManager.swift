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

    // MARK: - Heart Rate

    /// Fetches heart rate samples within a workout window and returns the average BPM.
    func fetchHeartRate(from start: Date, to end: Date, completion: @escaping (Double?) -> Void) {
        guard let hrType = HKObjectType.quantityType(forIdentifier: .heartRate) else {
            completion(nil); return
        }
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        let query = HKSampleQuery(
            sampleType: hrType,
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: nil
        ) { _, samples, _ in
            guard let samples = samples as? [HKQuantitySample], !samples.isEmpty else {
                completion(nil); return
            }
            let total = samples.reduce(0.0) {
                $0 + $1.quantity.doubleValue(for: HKUnit(from: "count/min"))
            }
            completion(total / Double(samples.count))
        }
        store.execute(query)
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
