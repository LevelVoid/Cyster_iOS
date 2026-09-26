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

        setValue(goal1.id,                 forKey: "goal1ID")
        setValue(goal1.title,              forKey: "goal1Title")
        setValue(goal1.sentence,           forKey: "goal1Sentence")
        setValue(goal1.category,           forKey: "goal1Category")
        setValue(goal1.targetType,         forKey: "goal1TargetType")
        setValue(goal1.targetValue,        forKey: "goal1TargetValue")
        setValue(goal1.currentValue,       forKey: "goal1CurrentValue")
        setValue(false,                    forKey: "goal1Completed")
        setValue(goal1.celebrationMessage, forKey: "goal1Celebration")

        setValue(goal2.id,                 forKey: "goal2ID")
        setValue(goal2.title,              forKey: "goal2Title")
        setValue(goal2.sentence,           forKey: "goal2Sentence")
        setValue(goal2.category,           forKey: "goal2Category")
        setValue(goal2.targetType,         forKey: "goal2TargetType")
        setValue(goal2.targetValue,        forKey: "goal2TargetValue")
        setValue(goal2.currentValue,       forKey: "goal2CurrentValue")
        setValue(false,                    forKey: "goal2Completed")
        setValue(goal2.celebrationMessage, forKey: "goal2Celebration")
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
        guard
            let id1    = value(forKey: "goal1ID")        as? String,
            let title1 = value(forKey: "goal1Title")     as? String,
            let sent1  = value(forKey: "goal1Sentence")  as? String,
            let cat1   = value(forKey: "goal1Category")  as? String,
            let id2    = value(forKey: "goal2ID")        as? String,
            let title2 = value(forKey: "goal2Title")     as? String,
            let sent2  = value(forKey: "goal2Sentence")  as? String,
            let cat2   = value(forKey: "goal2Category")  as? String
        else { return nil }

        let goal1 = GoalCard(
            id:                 id1,
            title:              title1,
            sentence:           sent1,
            category:           cat1,
            targetType:         value(forKey: "goal1TargetType")   as? String ?? "manual",
            targetValue:        value(forKey: "goal1TargetValue")   as? Double ?? 0,
            currentValue:       value(forKey: "goal1CurrentValue")  as? Double ?? 0,
            completionRule:     "current>=target",
            celebrationMessage: value(forKey: "goal1Celebration")  as? String ?? "Goal completed!"
        )
        let isCompleted1 = value(forKey: "goal1Completed") as? Bool ?? false

        let goal2 = GoalCard(
            id:                 id2,
            title:              title2,
            sentence:           sent2,
            category:           cat2,
            targetType:         value(forKey: "goal2TargetType")   as? String ?? "manual",
            targetValue:        value(forKey: "goal2TargetValue")   as? Double ?? 0,
            currentValue:       value(forKey: "goal2CurrentValue")  as? Double ?? 0,
            completionRule:     "current>=target",
            celebrationMessage: value(forKey: "goal2Celebration")  as? String ?? "Goal completed!"
        )
        let isCompleted2 = value(forKey: "goal2Completed") as? Bool ?? false

        // Return goals with completion state embedded via currentValue == targetValue
        var mGoal1 = goal1
        if isCompleted1 { mGoal1 = GoalCard(id: goal1.id, title: goal1.title, sentence: goal1.sentence,
                                             category: goal1.category, targetType: goal1.targetType,
                                             targetValue: goal1.targetValue, currentValue: goal1.targetValue,
                                             completionRule: goal1.completionRule,
                                             celebrationMessage: goal1.celebrationMessage) }
        var mGoal2 = goal2
        if isCompleted2 { mGoal2 = GoalCard(id: goal2.id, title: goal2.title, sentence: goal2.sentence,
                                             category: goal2.category, targetType: goal2.targetType,
                                             targetValue: goal2.targetValue, currentValue: goal2.targetValue,
                                             completionRule: goal2.completionRule,
                                             celebrationMessage: goal2.celebrationMessage) }
        return (mGoal1, mGoal2)
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
        setValue(current,   forKey: "goal1CurrentValue")
        setValue(completed, forKey: "goal1Completed")
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
        setValue(current,   forKey: "goal2CurrentValue")
        setValue(completed, forKey: "goal2Completed")
    }
}
