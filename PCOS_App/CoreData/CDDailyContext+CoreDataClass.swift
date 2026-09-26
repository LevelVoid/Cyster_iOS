//
// CDDailyContext+CoreDataClass.swift
//
// Purpose:
// Represents a single day's context for a user, containing metrics, logs, and goals.
//
// Why this exists:
// CoreData model for aggregating all daily health and activity data in one place.
//
import Foundation
import CoreData

@objc(CDDailyContext)
public class CDDailyContext: NSManagedObject {

    var totalCalories: Int {
        if healthKitCalories > 0 {
            return Int(healthKitCalories + caloriesBurned)
        }
        return Int(caloriesBurned)
    }

    var sleepHours: Double? {
        guard let sleep = sleepTime, let wake = wakeTime else { return nil }
        return wake.timeIntervalSince(sleep) / 3600.0
    }

    func toDailyActivity() -> DailyActivity {
        DailyActivity(
            date: date ?? Date(),
            steps: Int(steps),
            caloriesBurned: Int(caloriesBurned),
            activeDurationSeconds: Int(activeDurationSeconds),
            healthKitCalories: Int(healthKitCalories)
        )
    }

    // MARK: - Milestone 6A: Goal Persistence Helpers

    ///
    /// Whether today's context already has persisted goals.
    ///
    /// Why this exists:
    /// Prevents regenerating goals when valid ones are already saved for today.
    ///
    var hasGoalsForToday: Bool {
        guard let generatedDate = value(forKey: "goalsGeneratedDate") as? Date else { return false }
        return Calendar.current.isDateInToday(generatedDate)
    }

    ///
    /// Writes a pair of GoalCard values into the CoreData context.
    ///
    /// Why this exists:
    /// Single entry point for persisting AI-generated goals. Stamps the generation date
    /// so `hasGoalsForToday` works correctly.
    ///
    /// - Parameters:
    ///   - goal1: The first generated GoalCard.
    ///   - goal2: The second generated GoalCard.
    func persistGoals(goal1: GoalCard, goal2: GoalCard) {
        setValue(Date(), forKey: "goalsGeneratedDate")

        let d1 = DailyGoal(id: goal1.id, title: goal1.title, sentence: goal1.sentence, category: goal1.category, targetType: goal1.targetType, targetValue: goal1.targetValue, currentValue: goal1.currentValue, isCompleted: false, completionRule: goal1.completionRule, celebrationMessage: goal1.celebrationMessage, generatedReason: "")
        let d2 = DailyGoal(id: goal2.id, title: goal2.title, sentence: goal2.sentence, category: goal2.category, targetType: goal2.targetType, targetValue: goal2.targetValue, currentValue: goal2.currentValue, isCompleted: false, completionRule: goal2.completionRule, celebrationMessage: goal2.celebrationMessage, generatedReason: "")
        
        if let encoded = try? JSONEncoder().encode([d1, d2]) {
            setValue(encoded, forKey: "dailyGoalsData")
        }
    }

    ///
    /// Reconstructs the persisted GoalCard pair from CoreData.
    ///
    /// Why this exists:
    /// Allows DailyGoalManager to load today's goals from CoreData without
    /// an AI call when goals have already been generated today.
    ///
    /// - Returns: A tuple of (GoalCard, GoalCard) or nil if no goals persisted.
    func loadPersistedGoals() -> (GoalCard, GoalCard)? {
        guard let data = value(forKey: "dailyGoalsData") as? Data,
              let goals = try? JSONDecoder().decode([DailyGoal].self, from: data),
              goals.count >= 2 else {
            return nil
        }

        let d1 = goals[0]
        let d2 = goals[1]

        var goal1 = GoalCard(
            id: d1.id,
            title: d1.title,
            sentence: d1.sentence,
            category: d1.category,
            targetType: d1.targetType,
            targetValue: d1.targetValue,
            currentValue: d1.currentValue,
            completionRule: d1.completionRule,
            celebrationMessage: d1.celebrationMessage
        )
        if d1.isCompleted {
            goal1.currentValue = goal1.targetValue
        }

        var goal2 = GoalCard(
            id: d2.id,
            title: d2.title,
            sentence: d2.sentence,
            category: d2.category,
            targetType: d2.targetType,
            targetValue: d2.targetValue,
            currentValue: d2.currentValue,
            completionRule: d2.completionRule,
            celebrationMessage: d2.celebrationMessage
        )
        if d2.isCompleted {
            goal2.currentValue = goal2.targetValue
        }

        return (goal1, goal2)
    }

    ///
    /// Updates the currentValue and completed state for goal 1.
    ///
    /// Why this exists:
    /// Called by DailyGoalManager.evaluateCompletion() when a relevant event is logged.
    ///
    /// - Parameters:
    ///   - current: The updated progress value.
    ///   - completed: Whether the goal is now complete.
    func updateGoal1Progress(current: Double, completed: Bool) {
        guard let data = value(forKey: "dailyGoalsData") as? Data,
              var goals = try? JSONDecoder().decode([DailyGoal].self, from: data),
              goals.count >= 2 else { return }
              
        goals[0].currentValue = current
        goals[0].isCompleted = completed
        
        if let encoded = try? JSONEncoder().encode(goals) {
            setValue(encoded, forKey: "dailyGoalsData")
        }
    }

    ///
    /// Updates the currentValue and completed state for goal 2.
    ///
    /// Why this exists:
    /// Called by DailyGoalManager.evaluateCompletion() when a relevant event is logged.
    ///
    /// - Parameters:
    ///   - current: The updated progress value.
    ///   - completed: Whether the goal is now complete.
    func updateGoal2Progress(current: Double, completed: Bool) {
        guard let data = value(forKey: "dailyGoalsData") as? Data,
              var goals = try? JSONDecoder().decode([DailyGoal].self, from: data),
              goals.count >= 2 else { return }
              
        goals[1].currentValue = current
        goals[1].isCompleted = completed
        
        if let encoded = try? JSONEncoder().encode(goals) {
            setValue(encoded, forKey: "dailyGoalsData")
        }
    }
}
