import Foundation
import CoreData
import UIKit

final class CycleDataStore {

    static let shared = CycleDataStore()
    private let calendar = Calendar.current
    private let predictionEngine = PeriodPredictionEngine()

    var injectedContext: NSManagedObjectContext?

    private var context: NSManagedObjectContext {
        if let injected = injectedContext {
            return injected
        }
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return appDelegate.viewContext
    }

    private(set) var cycles: [CycleData] = []

    private init() {
        migrateIfNeeded()
        loadCycles()
    }

    private func migrateIfNeeded() {
        let migrationKey = "CycleDataStore_v2_migrated"
        guard !UserDefaults.standard.bool(forKey: migrationKey) else { return }

        UserDefaults.standard.removeObject(forKey: "SavedCycles")
        UserDefaults.standard.set(true, forKey: migrationKey)
    }
}

private struct CycleSeed {
    let startDate: Date
    let cycleLength: Int
    let periodLength: Int
}

extension CycleDataStore {
    var nextPeriodPrediction: PeriodPrediction {
        predictionEngine.predict(from: cycles)
    }
}

extension CycleDataStore {

    func loadCycles() {

        let request: NSFetchRequest<CDCycleData> = CDCycleData.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "startDate", ascending: false)]

        do {
            let cdCycles = try context.fetch(request)
            if !cdCycles.isEmpty {

                cycles = cdCycles.map { $0.toCycleData(using: self) }
                return
            }
        } catch {
            print("❌ Failed to fetch CDCycleData: \(error)")
        }

        if let timestamps = UserDefaults.standard.array(forKey: "SavedPeriodDates") as? [TimeInterval] {
            let dates = timestamps.map { calendar.startOfDay(for: Date(timeIntervalSince1970: $0)) }
            if !dates.isEmpty {
                rebuildCycles(from: dates)
                return
            }
        }
        cycles = []
    }

    func loadRecentCycles(count: Int = 6) -> [CycleData] {
        Array(cycles.prefix(count))
    }

    var hasTwoCycles: Bool {
        cycles.count >= 2
    }

    var currentCycle: CycleData? {
        let today = calendar.startOfDay(for: Date())
        return cycles
            .filter { calendar.startOfDay(for: $0.startDate) <= today }
            .sorted { $0.startDate > $1.startDate }
            .first
    }

    func previousCycles(count: Int = 3) -> [CycleData] {
        guard let current = currentCycle else {
            return Array(cycles.prefix(count))
        }
        let prev = cycles
            .filter { $0.id != current.id }
            .sorted { $0.startDate > $1.startDate }
        return Array(prev.prefix(count))
    }

    var averageCompletedCycleLength: Int {
        let completed = cycles.filter { $0.isComplete }
        let lengths = completed.map { $0.cycleLength }.filter { $0 > 0 }
        guard !lengths.isEmpty else { return 35 }
        return lengths.reduce(0, +) / lengths.count
    }
}

extension CycleDataStore {

    func phaseForDay(
        day: Int,
        cycleLength: Int,
        periodLength: Int,
        isOvulationConfirmed: Bool = false
    ) -> Phase {

        guard cycleLength > 0, day >= 1 else { return .unknown }

        if day <= periodLength {
            return .menstrual
        }

        if cycleLength > 45 && !isOvulationConfirmed {
            if day <= periodLength { return .menstrual }       
            if day <= periodLength + 5 { return .follicular }  
            return .unknown                                    
        }

        let estimatedLutealLength = averageLutealLength()      

        let ovulationCenter = max(cycleLength - estimatedLutealLength, periodLength + 1)

        let ovulationStart = max(ovulationCenter - 1, periodLength + 1)
        let ovulationEnd   = min(ovulationCenter + 1, cycleLength)

        let follicularStart = periodLength + 1
        let follicularEnd   = ovulationStart - 1

        if day >= follicularStart && day <= follicularEnd {
            return .follicular
        }
        if day >= ovulationStart && day <= ovulationEnd {
            return .ovulation
        }
        if day > ovulationEnd {
            return .luteal
        }

        return .follicular
    }

    func currentPhaseInfo() -> (cycleDay: Int, phase: Phase) {
        let today = calendar.startOfDay(for: Date())

        guard let latestCycle = cycles
            .filter({ calendar.startOfDay(for: $0.startDate) <= today })
            .sorted(by: { $0.startDate > $1.startDate })
            .first else {
            return (0, .unknown)       
        }

        let startOfCycle = calendar.startOfDay(for: latestCycle.startDate)
        let daysDiff = calendar.dateComponents([.day], from: startOfCycle, to: today).day ?? 0
        let cycleDay = daysDiff + 1

        if cycleDay < 1 {
            return (1, .unknown)
        }

        if cycleDay > latestCycle.cycleLength {
            return (cycleDay, latestCycle.isOvulationConfirmed ? .luteal : .unknown)
        }

        let phase = phaseForDay(
            day: cycleDay,
            cycleLength: latestCycle.cycleLength,
            periodLength: latestCycle.periodLength,
            isOvulationConfirmed: latestCycle.isOvulationConfirmed
        )
        return (cycleDay, phase)
    }

    private func averageLutealLength() -> Int {
        let completed = cycles.filter { $0.isComplete && $0.cycleLength > 0 && $0.periodLength > 0 }
        guard completed.count >= 2 else { return 13 }   

        let lutealEstimates = completed.suffix(4).map { cycle -> Int in

            let ovEst = max(Int(Double(cycle.cycleLength) * 0.58), cycle.periodLength + 1)
            return cycle.cycleLength - ovEst
        }

        let avg = lutealEstimates.reduce(0, +) / max(lutealEstimates.count, 1)
        return min(max(avg, 10), 16)    
    }
}

private extension CycleDataStore {

    func symptomsForDay(dayIndex: Int, cycleStartDate: Date) -> [SymptomItem] {
        guard let date = calendar.date(
            byAdding: .day,
            value: dayIndex - 1,
            to: cycleStartDate
        ) else { return [] }
        return SymptomDataStore.loadSymptoms(for: date)
    }

    func generateCycleDays(from seed: CycleSeed) -> [CycleDay] {
        guard seed.cycleLength > 0 else { return [] }
        return (1...seed.cycleLength).map { day in
            CycleDay(
                dayIndex: day,
                phase: phaseForDay(
                    day: day,
                    cycleLength: seed.cycleLength,
                    periodLength: seed.periodLength
                ),
                symptoms: symptomsForDay(
                    dayIndex: day,
                    cycleStartDate: seed.startDate
                ),
                basalBodyTemperature: nil
            )
        }
    }

    func monthString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

extension CycleDataStore {

    func rebuildCycles(from allDates: [Date]) {

        let sorted = allDates.map { calendar.startOfDay(for: $0) }.sorted()

        guard !sorted.isEmpty else {
            cycles = []

            let deleteRequest: NSFetchRequest<NSFetchRequestResult> = CDCycleData.fetchRequest()
            let batchDelete = NSBatchDeleteRequest(fetchRequest: deleteRequest)
            batchDelete.resultType = .resultTypeObjectIDs
            if let result = try? context.execute(batchDelete) as? NSBatchDeleteResult,
               let objectIDs = result.result as? [NSManagedObjectID] {
                NSManagedObjectContext.mergeChanges(
                    fromRemoteContextSave: [NSDeletedObjectsKey: objectIDs],
                    into: [context]
                )
            }
            return
        }

        var periodGroups: [[Date]] = [[sorted[0]]]
        for i in 1..<sorted.count {
            let gap = calendar.dateComponents(
                [.day], from: sorted[i - 1], to: sorted[i]
            ).day ?? 0
            if gap <= 1 {
                periodGroups[periodGroups.count - 1].append(sorted[i])
            } else {
                periodGroups.append([sorted[i]])
            }
        }
        periodGroups.sort { ($0.first ?? .distantPast) < ($1.first ?? .distantPast) }

        var completedLengths: [Int] = []
        for idx in 0..<periodGroups.count - 1 {
            let thisStart = calendar.startOfDay(for: periodGroups[idx].first!)
            let nextStart = calendar.startOfDay(for: periodGroups[idx + 1].first!)
            let gap = calendar.dateComponents([.day], from: thisStart, to: nextStart).day ?? 28
            completedLengths.append(max(gap, periodGroups[idx].count))
        }

        let avgCompleted: Int
        if completedLengths.isEmpty {
            avgCompleted = 35                          
        } else {
            avgCompleted = completedLengths.reduce(0, +) / completedLengths.count
        }

        var finalCycles: [CycleData] = []

        for (idx, group) in periodGroups.enumerated() {
            let startDate = group.first!
            let periodLength = group.count
            let isLast = idx == periodGroups.count - 1

            let cycleLength: Int
            let endDate: Date?

            if !isLast {

                cycleLength = completedLengths[idx]
                let nextStart = calendar.startOfDay(for: periodGroups[idx + 1].first!)
                endDate = calendar.date(byAdding: .day, value: -1, to: nextStart)
            } else {

                let today = calendar.startOfDay(for: Date())
                let daysSoFar = calendar.dateComponents([.day], from: calendar.startOfDay(for: startDate), to: today).day ?? 0

                cycleLength = max(avgCompleted, daysSoFar + 7)
                endDate = nil
            }

            let seed = CycleSeed(
                startDate: startDate,
                cycleLength: cycleLength,
                periodLength: periodLength
            )

            finalCycles.append(CycleData(
                id: UUID(),
                month: monthString(from: startDate),
                startDate: startDate,
                endDate: endDate,
                isOvulationConfirmed: false,
                days: generateCycleDays(from: seed)
            ))
        }

        cycles = finalCycles.sorted { $0.startDate > $1.startDate }

        saveToCoreData(from: cycles)

        UserDefaults.standard.removeObject(forKey: "SavedCycles")
    }

    private func saveToCoreData(from cycleDataArray: [CycleData]) {

        let deleteRequest: NSFetchRequest<NSFetchRequestResult> = CDCycleData.fetchRequest()
        let batchDelete = NSBatchDeleteRequest(fetchRequest: deleteRequest)
        batchDelete.resultType = .resultTypeObjectIDs

        do {
            let result = try context.execute(batchDelete) as? NSBatchDeleteResult
            if let objectIDs = result?.result as? [NSManagedObjectID] {
                NSManagedObjectContext.mergeChanges(
                    fromRemoteContextSave: [NSDeletedObjectsKey: objectIDs],
                    into: [context]
                )
            }
        } catch {
            print("❌ Failed to delete old CDCycleData: \(error)")
        }

        for cycle in cycleDataArray {
            let cdCycle = CDCycleData(context: context)
            cdCycle.id = cycle.id
            cdCycle.startDate = cycle.startDate
            cdCycle.endDate = cycle.endDate
            cdCycle.periodLength = Int16(cycle.periodLength)
            cdCycle.cycleLength = cycle.isComplete ? Int16(cycle.cycleLength) : 0
            cdCycle.isOvulationConfirmed = cycle.isOvulationConfirmed
        }

        if context.hasChanges {
            do {
                try context.save()
                print("✅ \(cycleDataArray.count) cycles saved to Core Data")
            } catch {
                print("❌ Core Data save error: \(error)")
            }
        }
    }

}
