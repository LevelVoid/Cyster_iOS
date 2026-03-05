//
//  CycleDataStore.swift
//  PCOS_App
//
//  Created by Abhinaya Rajarajan on 17/02/26.
//
import Foundation

final class CycleDataStore {

    static let shared = CycleDataStore()
    private let calendar = Calendar.current

    private(set) var cycles: [CycleData] = []

    private init() {
        loadCycles()
    }
}

extension CycleDataStore {
    private func generateMockCycles(count: Int) -> [CycleData] {
        let seeds = mockCycleSeeds(count: count)

        return seeds.map { seed in
            CycleData(
                id: UUID(),
                month: monthString(from: seed.startDate),
                startDate: seed.startDate,
                days: generateCycleDays(from: seed)
            )
        }
    }

}
private struct CycleSeed {
    let startDate: Date
    let cycleLength: Int
    let periodLength: Int
}

private extension CycleDataStore {

    func mockCycleSeeds(count: Int) -> [CycleSeed] {

        let today = calendar.startOfDay(for: Date())

        return [
            CycleSeed(
                startDate: calendar.date(byAdding: .day, value: -30, to: today)!,
                cycleLength: 29,
                periodLength: 4
            ),
            CycleSeed(
                startDate: calendar.date(byAdding: .day, value: -60, to: today)!,
                cycleLength: 27,
                periodLength: 5
            ),
            CycleSeed(
                startDate: calendar.date(byAdding: .day, value: -100, to: today)!,
                cycleLength: 31,
                periodLength: 4
            )
        ].prefix(count).map { $0 }
    }
    
}
extension CycleDataStore {

    func loadCycles() {
        if let data = UserDefaults.standard.data(forKey: "SavedCycles"),
           let decoded = try? JSONDecoder().decode([CycleData].self, from: data) {
            cycles = decoded
        } else {
            cycles = generateMockCycles(count: 3)
        }
    }

    func saveCycles() {
        if let data = try? JSONEncoder().encode(cycles) {
            UserDefaults.standard.set(data, forKey: "SavedCycles")
        }
    }

    func loadRecentCycles(count: Int = 6) -> [CycleData] {
        Array(cycles.prefix(count))
    }

    // MARK: - Current & Previous Cycle Helpers

    /// The most-recent (ongoing) cycle — the one whose startDate is closest to today
    /// and whose startDate is not in the future.
    var currentCycle: CycleData? {
        let today = calendar.startOfDay(for: Date())
        return cycles
            .filter { calendar.startOfDay(for: $0.startDate) <= today }
            .sorted { $0.startDate > $1.startDate }
            .first
    }

    /// The `count` completed cycles that come before the current cycle,
    /// sorted newest-first.
    func previousCycles(count: Int = 3) -> [CycleData] {
        guard let current = currentCycle else {
            return Array(cycles.prefix(count))
        }
        let prev = cycles
            .filter { $0.id != current.id }
            .sorted { $0.startDate > $1.startDate }
        return Array(prev.prefix(count))
    }
}

extension CycleDataStore {

    func phaseForDay(
        day: Int,
        cycleLength: Int,
        periodLength: Int
    ) -> Phase {

        if day <= periodLength {
            return .menstrual
        }

        let ovulationDay = max(cycleLength - 14, periodLength + 1)
        let fertileStart = max(ovulationDay - 4, periodLength + 1)
        let fertileEnd = ovulationDay + 1

        if day == ovulationDay {
            return .ovulation
        }

        if day >= fertileStart && day <= fertileEnd {
            return .follicular
        }

        if day > ovulationDay {
            return .luteal
        }

        // Post-period but before fertile window → early follicular
        return .follicular
    }

    func currentPhaseInfo() -> (cycleDay: Int, phase: Phase) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Always use the cycle with the most-recent startDate that is ≤ today
        guard let latestCycle = cycles
            .filter({ calendar.startOfDay(for: $0.startDate) <= today })
            .sorted(by: { $0.startDate > $1.startDate })
            .first else {
            return (1, .luteal)
        }

        let startOfCycle = calendar.startOfDay(for: latestCycle.startDate)
        let daysDiff = calendar.dateComponents([.day], from: startOfCycle, to: today).day ?? 0
        let cycleDay = daysDiff + 1

        if cycleDay < 1 {
            return (1, .luteal)
        }

        // If past the expected cycle length, still show the real day count
        // but treat as late luteal (waiting for next period)
        if cycleDay > latestCycle.cycleLength {
            return (cycleDay, .luteal)
        }

        let phase = phaseForDay(
            day: cycleDay,
            cycleLength: latestCycle.cycleLength,
            periodLength: latestCycle.periodLength
        )
        return (cycleDay, phase)
    }
}
private extension CycleDataStore {

    func symptomsForDay(
        dayIndex: Int,
        cycleStartDate: Date
    ) -> [SymptomItem] {

        guard let date = calendar.date(
            byAdding: .day,
            value: dayIndex - 1,
            to: cycleStartDate
        ) else {
            return []
        }

        return SymptomDataStore.loadSymptoms(for: date)
    }
}
private extension CycleDataStore {

    func generateCycleDays(from seed: CycleSeed) -> [CycleDay] {

        (1...seed.cycleLength).map { day in
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
                )
            )
        }
    }
}
private extension CycleDataStore {

    func monthString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}
extension CycleDataStore {

    /// Rebuilds ALL cycles from the selected period dates.
    ///
    /// The calendar preloads dates from existing cycles, so `allDates`
    /// is the single source of truth.  Deselecting dates removes them.
    func rebuildCycles(from allDates: [Date]) {

        let sorted = allDates.map { calendar.startOfDay(for: $0) }.sorted()

        // If no dates remain, clear saved data and fall back to mock cycles
        guard !sorted.isEmpty else {
            cycles = generateMockCycles(count: 3)
            UserDefaults.standard.removeObject(forKey: "SavedCycles")
            return
        }

        // ── 1. Group into contiguous period runs (gap > 1 = new period) ──
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

        // ── 2. Build a cycle for each period group ──
        var newCycles: [CycleData] = []
        for group in periodGroups {
            let startDate = group.first!
            let periodLength = group.count
            let seed = CycleSeed(
                startDate: startDate,
                cycleLength: 28, // placeholder, recalculated below
                periodLength: periodLength
            )
            newCycles.append(CycleData(
                id: UUID(),
                month: monthString(from: startDate),
                startDate: startDate,
                days: generateCycleDays(from: seed)
            ))
        }

        // ── 3. Recalculate cycle lengths from gaps between starts ──
        var finalCycles: [CycleData] = []
        for (idx, cycle) in newCycles.enumerated() {
            let periodLength = cycle.periodLength
            let cycleLength: Int

            if idx < newCycles.count - 1 {
                let thisStart = calendar.startOfDay(for: cycle.startDate)
                let nextStart = calendar.startOfDay(for: newCycles[idx + 1].startDate)
                cycleLength = max(
                    calendar.dateComponents([.day], from: thisStart, to: nextStart).day ?? 28,
                    periodLength
                )
            } else {
                cycleLength = 28
            }

            let seed = CycleSeed(
                startDate: cycle.startDate,
                cycleLength: cycleLength,
                periodLength: periodLength
            )
            finalCycles.append(CycleData(
                id: cycle.id,
                month: monthString(from: cycle.startDate),
                startDate: cycle.startDate,
                days: generateCycleDays(from: seed)
            ))
        }

        // ── 4. Store newest-first ──
        cycles = finalCycles.sorted { $0.startDate > $1.startDate }
        saveCycles()
    }
}
