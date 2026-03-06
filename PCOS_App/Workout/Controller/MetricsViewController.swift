//
//  MetricsViewController.swift
//  PCOS_App
//
//  Created by SDC-USER on 21/01/26.
//

import UIKit
import SwiftUI

class MetricsViewController: UIViewController {
    
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var contentLabel: UILabel!
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var chartView: UIView!
    @IBOutlet weak var contentView: UIView!
    
    var goalType: GoalType = .calories
    private var dataPoints: [WorkoutChartDataPoint] = []
    private var hostingController: UIHostingController<WorkoutChartView>?
    private var currentTimeRange: WorkoutChartTimeRange = .week
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("MetricsViewController loaded with goalType: \(goalType.title)")
        
        title = goalType.title
        navigationController?.navigationBar.prefersLargeTitles = false
        
        segmentedControl?.selectedSegmentIndex = 0  // Week
        segmentedControl?.addTarget(self, action: #selector(timeSegmentChanged(_:)), for: .valueChanged)
        
        setupStyling()
        loadData(for: .week)
        setupChart()
        updateInsights()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadData(for: currentTimeRange)
        updateChart()
        updateInsights()
    }
    
    @objc func timeSegmentChanged(_ sender: UISegmentedControl) {
        let range = WorkoutChartTimeRange(rawValue: sender.selectedSegmentIndex) ?? .week
        print("Time range changed to: \(range)")
        currentTimeRange = range
        loadData(for: range)
        updateChart()
        updateInsights()
    }
    
    // MARK: - Data Loading

    private func loadData(for range: WorkoutChartTimeRange) {
        currentTimeRange = range
        switch goalType {
        case .calories:
            loadCaloriesData(for: range)
        case .steps:
            loadStepsData(for: range)
        case .duration:
            loadDurationData(for: range)
        }
    }

    // MARK: Calories — HealthKit per-day background + CompletedWorkoutsDataStore session cals
    private func loadCaloriesData(for range: WorkoutChartTimeRange) {
        let calendar = Calendar.current
        let now = Date()

        let startDate: Date
        switch range {
        case .week:  startDate = calendar.date(byAdding: .day,   value: -6,  to: calendar.startOfDay(for: now))!
        case .month: startDate = calendar.date(byAdding: .day,   value: -27, to: calendar.startOfDay(for: now))!
        case .year:  startDate = calendar.date(byAdding: .month, value: -11, to: calendar.startOfDay(for: now))!
        }

        // Fetch per-day HealthKit active calories for the whole range in one query
        HealthKitManager.shared.fetchDailyActiveCalories(from: startDate, to: now) { [weak self] hkCalsByDay in
            guard let self = self else { return }

            // Session calories from in-app workouts (persisted on disk)
            let allSessions = CompletedWorkoutsDataStore.shared.loadAll()

            /// Total session kcal for a given calendar day
            func sessionCals(on day: Date) -> Double {
                allSessions
                    .filter { calendar.isDate($0.date, inSameDayAs: day) }
                    .reduce(0.0) { $0 + $1.caloriesBurned }
            }

            var newData: [WorkoutChartDataPoint] = []

            switch range {
            case .week:
                let formatter = DateFormatter(); formatter.dateFormat = "EEE"
                for offset in (0..<7).reversed() {
                    guard let date = calendar.date(byAdding: .day, value: -offset, to: now) else { continue }
                    let day = calendar.startOfDay(for: date)
                    let hk  = hkCalsByDay[day] ?? 0
                    let ses = sessionCals(on: date)
                    // If HealthKit has data, add session on top; if only session data, use that alone
                    let total = hk > 0 ? hk + ses : ses
                    newData.append(WorkoutChartDataPoint(date: date, value: total, label: formatter.string(from: date)))
                }

            case .month:
                for weekOffset in (0..<4).reversed() {
                    guard let weekStart = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: now),
                          let weekEnd   = calendar.date(byAdding: .day, value: 7, to: weekStart) else { continue }
                    var weekTotal = 0.0
                    var activeDays = 0
                    var cur = calendar.startOfDay(for: weekStart)
                    while cur < weekEnd {
                        let hk  = hkCalsByDay[cur] ?? 0
                        let ses = sessionCals(on: cur)
                        let dayVal = hk > 0 ? hk + ses : ses
                        if dayVal > 0 { weekTotal += dayVal; activeDays += 1 }
                        cur = calendar.date(byAdding: .day, value: 1, to: cur)!
                    }
                    let avg = activeDays > 0 ? weekTotal / Double(activeDays) : 0
                    newData.append(WorkoutChartDataPoint(date: weekStart, value: avg, label: "W\(4 - weekOffset)"))
                }

            case .year:
                let formatter = DateFormatter(); formatter.dateFormat = "MMM"
                for monthOffset in (0..<12).reversed() {
                    guard let date = calendar.date(byAdding: .month, value: -monthOffset, to: now) else { continue }
                    let comps = calendar.dateComponents([.year, .month], from: date)
                    guard let monthStart = calendar.date(from: comps),
                          let monthEnd   = calendar.date(byAdding: .month, value: 1, to: monthStart) else { continue }
                    var monthTotal = 0.0
                    var activeDays = 0
                    var cur = monthStart
                    while cur < monthEnd {
                        let hk  = hkCalsByDay[cur] ?? 0
                        let ses = sessionCals(on: cur)
                        let dayVal = hk > 0 ? hk + ses : ses
                        if dayVal > 0 { monthTotal += dayVal; activeDays += 1 }
                        cur = calendar.date(byAdding: .day, value: 1, to: cur)!
                    }
                    let avg = activeDays > 0 ? monthTotal / Double(activeDays) : 0
                    newData.append(WorkoutChartDataPoint(date: monthStart, value: avg, label: formatter.string(from: monthStart)))
                }
            }

            DispatchQueue.main.async {
                self.dataPoints = newData.sorted { $0.date < $1.date }
                self.updateChart()
                self.updateInsights()
            }
        }
    }

    // MARK: Steps — HealthKit per-day (real data)
    private func loadStepsData(for range: WorkoutChartTimeRange) {
        let calendar = Calendar.current
        let now = Date()

        // Determine the query window
        let startDate: Date
        switch range {
        case .week:  startDate = calendar.date(byAdding: .day,   value: -6,  to: calendar.startOfDay(for: now))!
        case .month: startDate = calendar.date(byAdding: .day,   value: -27, to: calendar.startOfDay(for: now))!
        case .year:  startDate = calendar.date(byAdding: .month, value: -11, to: calendar.startOfDay(for: now))!
        }

        HealthKitManager.shared.fetchDailySteps(from: startDate, to: now) { [weak self] stepsByDay in
            guard let self = self else { return }
            var newData: [WorkoutChartDataPoint] = []

            switch range {
            case .week:
                let formatter = DateFormatter(); formatter.dateFormat = "EEE"
                for offset in (0..<7).reversed() {
                    guard let date = calendar.date(byAdding: .day, value: -offset, to: now) else { continue }
                    let day = calendar.startOfDay(for: date)
                    let value = Double(stepsByDay[day] ?? 0)
                    newData.append(WorkoutChartDataPoint(date: date, value: value, label: formatter.string(from: date)))
                }

            case .month:
                for weekOffset in (0..<4).reversed() {
                    guard let weekStart = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: now),
                          let weekEnd   = calendar.date(byAdding: .day, value: 7, to: weekStart) else { continue }
                    var weekTotal = 0
                    var activeDays = 0
                    var cur = calendar.startOfDay(for: weekStart)
                    while cur < weekEnd {
                        let s = stepsByDay[cur] ?? 0
                        if s > 0 { weekTotal += s; activeDays += 1 }
                        cur = calendar.date(byAdding: .day, value: 1, to: cur)!
                    }
                    let avg = activeDays > 0 ? Double(weekTotal) / Double(activeDays) : 0
                    newData.append(WorkoutChartDataPoint(date: weekStart, value: avg, label: "W\(4 - weekOffset)"))
                }

            case .year:
                let formatter = DateFormatter(); formatter.dateFormat = "MMM"
                for monthOffset in (0..<12).reversed() {
                    guard let date = calendar.date(byAdding: .month, value: -monthOffset, to: now) else { continue }
                    let comps = calendar.dateComponents([.year, .month], from: date)
                    guard let monthStart = calendar.date(from: comps),
                          let monthEnd   = calendar.date(byAdding: .month, value: 1, to: monthStart) else { continue }
                    var monthTotal = 0
                    var activeDays = 0
                    var cur = monthStart
                    while cur < monthEnd {
                        let s = stepsByDay[cur] ?? 0
                        if s > 0 { monthTotal += s; activeDays += 1 }
                        cur = calendar.date(byAdding: .day, value: 1, to: cur)!
                    }
                    let avg = activeDays > 0 ? Double(monthTotal) / Double(activeDays) : 0
                    newData.append(WorkoutChartDataPoint(date: monthStart, value: avg, label: formatter.string(from: monthStart)))
                }
            }

            DispatchQueue.main.async {
                self.dataPoints = newData.sorted { $0.date < $1.date }
                self.updateChart()
                self.updateInsights()
            }
        }
    }

    // MARK: Duration — CompletedWorkoutsDataStore (actual session durations only)
    private func loadDurationData(for range: WorkoutChartTimeRange) {
        let calendar = Calendar.current
        let now = Date()
        let allWorkouts = CompletedWorkoutsDataStore.shared.loadAll()
        var newData: [WorkoutChartDataPoint] = []

        /// Helper: total workout minutes on a given calendar day
        func minutesOnDay(_ day: Date) -> Double {
            let total = allWorkouts
                .filter { calendar.isDate($0.date, inSameDayAs: day) }
                .reduce(0) { $0 + $1.durationSeconds }
            return Double(total) / 60.0
        }

        switch range {
        case .week:
            let formatter = DateFormatter(); formatter.dateFormat = "EEE"
            for offset in (0..<7).reversed() {
                guard let date = calendar.date(byAdding: .day, value: -offset, to: now) else { continue }
                newData.append(WorkoutChartDataPoint(date: date, value: minutesOnDay(date), label: formatter.string(from: date)))
            }

        case .month:
            for weekOffset in (0..<4).reversed() {
                guard let weekStart = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: now) else { continue }
                var weekTotal = 0.0
                for d in 0..<7 {
                    if let day = calendar.date(byAdding: .day, value: d, to: weekStart) {
                        weekTotal += minutesOnDay(day)
                    }
                }
                newData.append(WorkoutChartDataPoint(date: weekStart, value: weekTotal / 7.0, label: "W\(4 - weekOffset)"))
            }

        case .year:
            let formatter = DateFormatter(); formatter.dateFormat = "MMM"
            for monthOffset in (0..<12).reversed() {
                guard let date = calendar.date(byAdding: .month, value: -monthOffset, to: now) else { continue }
                let comps = calendar.dateComponents([.year, .month], from: date)
                guard let monthStart = calendar.date(from: comps),
                      let monthEnd   = calendar.date(byAdding: .month, value: 1, to: monthStart) else { continue }
                let days = calendar.range(of: .day, in: .month, for: monthStart)?.count ?? 30
                let total = allWorkouts
                    .filter { $0.date >= monthStart && $0.date < monthEnd }
                    .reduce(0) { $0 + $1.durationSeconds }
                newData.append(WorkoutChartDataPoint(date: monthStart, value: Double(total) / 60.0 / Double(days), label: formatter.string(from: monthStart)))
            }
        }

        self.dataPoints = newData.sorted { $0.date < $1.date }
        updateChart()
    }


    // MARK: - View Setup
    private func setupChart() {
        guard let chartView = chartView else {
            print("chartView outlet is nil!")
            return
        }
        
        print("Setting up chart with \(dataPoints.count) data points")
        
        let swiftUIView = WorkoutChartView(
            dataPoints: dataPoints,
            goalType: goalType,
            timeRange: currentTimeRange
        )
        let hosting = UIHostingController(rootView: swiftUIView)
        
        addChild(hosting)
        hosting.view.frame = chartView.bounds
        hosting.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        hosting.view.backgroundColor = .clear
        
        chartView.addSubview(hosting.view)
        hosting.didMove(toParent: self)
        
        self.hostingController = hosting
        
        print("Chart setup complete")
    }
    
    private func updateChart() {
        print("Updating chart with \(dataPoints.count) data points")
        
        guard hostingController != nil else {
            setupChart()
            return
        }
        
        let swiftUIView = WorkoutChartView(
            dataPoints: dataPoints,
            goalType: goalType,
            timeRange: currentTimeRange
        )
        hostingController?.rootView = swiftUIView
    }
    
    private func setupStyling() {
        chartView?.layer.cornerRadius = 16
        chartView?.clipsToBounds = true
        chartView?.backgroundColor = .white
        contentView?.layer.cornerRadius = 16
    }
    
    private func updateInsights() {
        contentLabel?.text = getImportanceText()
    }
    
    private func getImportanceText() -> String {
        switch goalType {
        case .calories:
            return "Regular calorie burning through exercise helps improve insulin sensitivity and supports healthy weight management in PCOS."
        case .steps:
            return "Daily step goals help maintain consistent physical activity, which is crucial for managing PCOS symptoms and metabolic health."
        case .duration:
            return "Consistent workout duration builds endurance and helps regulate hormones, both essential for managing PCOS effectively."
        }
    }
}
