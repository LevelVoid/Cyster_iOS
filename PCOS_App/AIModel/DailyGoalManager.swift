//
// DailyGoalManager.swift
//
// Purpose:
// Orchestrates the full lifecycle of AI-generated daily missions:
// load, generate, persist, auto-complete, and refresh.
//
// Why this exists:
// Decouples daily goal logic from HomeViewController so that goal state
// is driven by CDDailyContext (Core Data) rather than in-memory AI calls.
// HomeViewController simply asks this manager for the current goals and
// reports events; the manager handles all logic.
//

import Foundation
import CoreData

/// The observation posted when a goal's progress or completion state changes.
/// HomeViewController listens to this to update the UI without polling.
extension Notification.Name {
    static let dailyGoalProgressUpdated = Notification.Name("dailyGoalProgressUpdated")
}

/// Represents the current render state of today's goals.
enum DailyGoalsState: Equatable {
    /// Manager has been created but no load has been attempted yet.
    case idle
    /// Goals have not been generated yet and generation is in progress.
    case loading
    /// Goals are fully loaded and ready to display.
    case loaded(DailyGoalsOutput)
    /// Generation failed with an error message.
    case failed(String)

    static func == (lhs: DailyGoalsState, rhs: DailyGoalsState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle): return true
        case (.loading, .loading): return true
        case (.failed(let a), .failed(let b)): return a == b
        case (.loaded, .loaded): return true   // shallow equality — UI always re-reads
        default: return false
        }
    }
}

///
/// DailyGoalManager — single source of truth for today's AI missions.
///
/// Public API:
/// - `loadTodayGoals()` — returns persisted goals if already generated, else calls AI.
/// - `generateIfNeeded()` — low-level entry point; called from `loadTodayGoals()`.
/// - `evaluateCompletion()` — checks all events and marks goals complete if thresholds are met.
/// - `refreshTomorrow()` — call when a new CDDailyContext is created.
///
@MainActor
final class DailyGoalManager {

    // MARK: - Singleton

    static let shared = DailyGoalManager()
    private init() {}

    // MARK: - Published State

    /// The current render state. HomeViewController reads this and observes the notification.
    private(set) var state: DailyGoalsState = .idle

    // MARK: - Private

    private var context: NSManagedObjectContext {
        PersistenceController.shared.container.viewContext
    }

    // MARK: - Public API

    ///
    /// Loads today's goals from persistence, or generates them if not yet created today.
    ///
    /// Why this exists:
    /// HomeViewController calls this once in `viewWillAppear`. If goals already exist
    /// in CDDailyContext for today, they are returned immediately (no AI call).
    /// If not, generation is triggered exactly once.
    ///
    /// Parameters: None
    /// Returns: Void
    /// Throws: None
    func loadTodayGoals() async {
        // 1. Attempt to load from CoreData
        if let todayCD = fetchTodayContext(), todayCD.hasGoalsForToday,
           let (g1, g2) = todayCD.loadPersistedGoals() {
            state = .loaded(DailyGoalsOutput(goals: [g1, g2]))
            return
        }

        // 2. Not yet generated — run generation
        await generateIfNeeded()
    }

    ///
    /// Generates today's goals if they have not yet been generated.
    ///
    /// Why this exists:
    /// Enforces the once-per-day contract. Guards against duplicate generation
    /// (e.g. if the user navigates away and back quickly).
    ///
    /// Parameters: None
    /// Returns: Void
    /// Throws: None
    func generateIfNeeded() async {
        // Block re-entrant calls only while actively generating.
        guard state != .loading else { return }
        // Skip if goals are already successfully loaded.
        if case .loaded = state { return }

        // Transition from .idle or .failed into .loading, then run generation.
        state = .loading

        let context = await SharedContextEngine.shared.buildDailyGoalContext()
        do {
            let output = try await AIBrain.shared.generateDailyGoals(context: context)
            guard output.goals.count >= 2 else {
                state = .failed("Insufficient goals generated.")
                return
            }
            let g1 = output.goals[0]
            let g2 = output.goals[1]

            // Persist to CoreData
            if let todayCD = fetchOrCreateTodayContext() {
                todayCD.persistGoals(goal1: g1, goal2: g2)
                try? self.context.save()
            }

            state = .loaded(output)
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    ///
    /// Evaluates whether any goal's completion threshold has been crossed.
    ///
    /// Why this exists:
    /// Called automatically after any relevant event (meal logged, workout saved, steps updated).
    /// This eliminates AI calls for completion — it's pure arithmetic.
    ///
    /// Parameters:
    ///   - event: The type of event that just occurred.
    /// Returns: Void
    /// Throws: None
    func evaluateCompletion(for event: GoalEvent) {
        guard let todayCD = fetchTodayContext(), todayCD.hasGoalsForToday,
              let (g1, g2) = todayCD.loadPersistedGoals() else { return }

        let currentProtein    = fetchTodayProtein()
        let currentWorkoutMin = fetchTodayWorkoutMinutes()
        let currentSteps      = fetchTodaySteps()

        // Evaluate goal 1
        let (prog1, done1) = evaluateGoal(g1,
                                          protein: currentProtein,
                                          workoutMinutes: currentWorkoutMin,
                                          steps: currentSteps,
                                          event: event)
        todayCD.updateGoal1Progress(current: prog1, completed: done1)

        // Evaluate goal 2
        let (prog2, done2) = evaluateGoal(g2,
                                          protein: currentProtein,
                                          workoutMinutes: currentWorkoutMin,
                                          steps: currentSteps,
                                          event: event)
        todayCD.updateGoal2Progress(current: prog2, completed: done2)

        // Save and notify UI
        try? context.save()

        // Rebuild loaded output reflecting new progress
        if let (updated1, updated2) = todayCD.loadPersistedGoals() {
            state = .loaded(DailyGoalsOutput(goals: [updated1, updated2]))
        }
        NotificationCenter.default.post(name: .dailyGoalProgressUpdated, object: nil)
    }

    ///
    /// Clears the in-memory state so the next day generates fresh goals.
    ///
    /// Why this exists:
    /// Called when a new CDDailyContext is created at midnight / app launch on a new day.
    /// The manager returns to `.loading` so the next `loadTodayGoals()` triggers generation.
    ///
    /// Parameters: None
    /// Returns: Void
    /// Throws: None
    func refreshTomorrow() {
        state = .loading
    }

    // MARK: - Private Helpers

    ///
    /// Calculates the new progress value and completion flag for a single goal.
    ///
    /// Parameters:
    ///   - goal: The GoalCard to evaluate.
    ///   - protein: Today's total logged protein (g).
    ///   - workoutMinutes: Today's total workout minutes.
    ///   - steps: Today's step count.
    ///   - event: The event that triggered this evaluation.
    /// Returns: `(updatedCurrent, isCompleted)` tuple.
    /// Throws: None
    private func evaluateGoal(
        _ goal: GoalCard,
        protein: Double,
        workoutMinutes: Double,
        steps: Double,
        event: GoalEvent
    ) -> (Double, Bool) {
        // Don't un-complete a completed goal
        if goal.currentValue >= goal.targetValue && goal.targetValue > 0
            && goal.completionRule == "current>=target" {
            return (goal.currentValue, true)
        }

        switch goal.targetType {
        case "protein":
            let done = protein >= goal.targetValue
            return (protein, done)

        case "workoutMinutes":
            let done = workoutMinutes >= goal.targetValue
            return (workoutMinutes, done)

        case "steps":
            let done = steps >= goal.targetValue
            return (steps, done)

        case "symptom":
            // Complete when a symptom-relief action is logged
            if case .symptomLogged = event {
                return (goal.targetValue, true)
            }
            return (goal.currentValue, false)

        default:
            // Manual goals — never auto-complete
            return (goal.currentValue, false)
        }
    }

    ///
    /// Fetches today's CDDailyContext, or nil if not yet created.
    ///
    /// Parameters: None
    /// Returns: CDDailyContext or nil
    /// Throws: None
    private func fetchTodayContext() -> CDDailyContext? {
        let cal = Calendar.current
        let start = cal.startOfDay(for: Date())
        let end   = cal.date(byAdding: .day, value: 1, to: start) ?? Date()
        let req: NSFetchRequest<CDDailyContext> = CDDailyContext.fetchRequest()
        req.predicate = NSPredicate(format: "date >= %@ AND date < %@",
                                    start as NSDate, end as NSDate)
        req.fetchLimit = 1
        return try? context.fetch(req).first
    }

    ///
    /// Fetches or creates today's CDDailyContext.
    ///
    /// Why this exists:
    /// Goals must be persisted even if CDDailyContext was not yet created by the app's
    /// normal flow (e.g. user hasn't logged anything yet today).
    ///
    /// Parameters: None
    /// Returns: CDDailyContext or nil
    /// Throws: None
    private func fetchOrCreateTodayContext() -> CDDailyContext? {
        if let existing = fetchTodayContext() { return existing }
        let cd = CDDailyContext(context: context)
        cd.setValue(Calendar.current.startOfDay(for: Date()), forKey: "date")
        cd.setValue(UUID(), forKey: "id")
        return cd
    }

    ///
    /// Returns today's total logged protein in grams.
    ///
    /// Parameters: None
    /// Returns: Double representing protein in grams
    /// Throws: None
    private func fetchTodayProtein() -> Double {
        let cal = Calendar.current
        let start = cal.startOfDay(for: Date())
        let end   = cal.date(byAdding: .day, value: 1, to: start) ?? Date()
        let req = NSFetchRequest<NSManagedObject>(entityName: "CDFoodLog")
        req.predicate = NSPredicate(format: "timeStamp >= %@ AND timeStamp < %@",
                                    start as NSDate, end as NSDate)
        let logs = (try? context.fetch(req)) ?? []
        return logs.reduce(0) { $0 + (($1.value(forKey: "proteinContent") as? Double) ?? 0) }
    }

    ///
    /// Returns today's total workout duration in minutes.
    ///
    /// Parameters: None
    /// Returns: Double representing workout duration in minutes
    /// Throws: None
    private func fetchTodayWorkoutMinutes() -> Double {
        guard let todayCD = fetchTodayContext() else { return 0 }
        let workouts = todayCD.value(forKey: "completedWorkouts") as? Set<NSManagedObject> ?? []
        let totalSeconds = workouts.reduce(0) {
            $0 + (($1.value(forKey: "durationSeconds") as? Int32) ?? 0)
        }
        return Double(totalSeconds) / 60.0
    }

    ///
    /// Returns today's step count from CDDailyContext.
    ///
    /// Parameters: None
    /// Returns: Double representing step count
    /// Throws: None
    private func fetchTodaySteps() -> Double {
        guard let todayCD = fetchTodayContext() else { return 0 }
        return Double((todayCD.value(forKey: "steps") as? Int32) ?? 0)
    }
}

// MARK: - GoalEvent

///
/// Represents an event type that can trigger goal auto-completion evaluation.
///
/// Why this exists:
/// Provides a typed, self-documenting API so HomeViewController and other callers
/// don't need to know which goal types each event affects.
///
enum GoalEvent {
    /// A meal was logged — affects protein goals.
    case mealLogged
    /// A workout was completed — affects workoutMinutes goals.
    case workoutCompleted
    /// Steps were synced from HealthKit — affects steps goals.
    case stepsUpdated
    /// A symptom was logged — affects symptom-relief goals.
    case symptomLogged
}
