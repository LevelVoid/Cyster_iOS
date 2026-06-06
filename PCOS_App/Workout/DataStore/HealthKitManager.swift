import Foundation
import HealthKit

final class HealthKitManager {

    static let shared = HealthKitManager()
    private let store = HKHealthStore()

    private init() {}

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

    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(false, nil)
            return
        }
        store.requestAuthorization(toShare: writeTypes, read: readTypes, completion: completion)
    }

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

    func fetchActiveCalories(from start: Date, to end: Date, completion: @escaping (Double) -> Void) {
        guard let calType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) else {
            completion(0); return
        }

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

    func fetchHeartRate(from start: Date, to end: Date, completion: @escaping (Double?) -> Void) {
        guard let hrType = HKObjectType.quantityType(forIdentifier: .heartRate) else {
            completion(nil); return
        }

        let exactPredicate = HKQuery.predicateForSamples(withStart: start, end: end, options: [])
        let exactQuery = HKSampleQuery(
            sampleType: hrType,
            predicate: exactPredicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: nil
        ) { [weak self] _, samples, _ in
            guard let self = self else { return }
            if let samples = samples as? [HKQuantitySample], !samples.isEmpty {

                let avg = samples.reduce(0.0) { $0 + $1.quantity.doubleValue(for: HKUnit(from: "count/min")) }
                    / Double(samples.count)
                completion(avg)
            } else {

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

    func estimateCaloriesFromHeartRate(
        avgHR: Double,
        ageYears: Int,
        weightKg: Double,
        durationMin: Double,
        isFemale: Bool = true
    ) -> Double {

        let age = Double(ageYears)
        let calPerMin: Double
        if isFemale {
            calPerMin = (-20.4022 + 0.4472 * avgHR - 0.1263 * weightKg + 0.074 * age) / 4.184
        } else {
            calPerMin = (-55.0969 + 0.6309 * avgHR - 0.1988 * weightKg + 0.2017 * age) / 4.184
        }
        return max(0, calPerMin * durationMin)
    }

    func fetchSleepLastNight(completion: @escaping (SleepData?) -> Void) {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            completion(nil); return
        }
        let calendar = Calendar.current
        let now = Date()

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

extension HealthKitManager {

    var userAge: Int {
        let dob = UserDefaults.standard.object(forKey: "userDOB") as? Date
        guard let dob = dob else { return 27 }
        return Calendar.current.dateComponents([.year], from: dob, to: Date()).year ?? 27
    }

    var userWeightKg: Double {
        let weight = UserDefaults.standard.double(forKey: "userWeightKg")
        return weight > 0 ? weight : 60.0
    }
}
