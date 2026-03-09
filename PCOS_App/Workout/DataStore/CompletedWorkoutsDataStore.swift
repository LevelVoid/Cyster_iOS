import Foundation
import CoreData
import UIKit

final class CompletedWorkoutsDataStore {

    static let shared = CompletedWorkoutsDataStore()
    
    private static var context: NSManagedObjectContext {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return appDelegate.viewContext
    }
    
    private init() {
        if loadAll().isEmpty {
            CompletedWorkoutsDataStore.migrateLegacyDataIfNeeded()
        }
    }

    // MARK: - Save
    func save(_ workout: CompletedWorkout) {
        let ctx = Self.context
        
        let cdWorkout = CDCompletedWorkout(context: ctx)
        cdWorkout.id = workout.id
        cdWorkout.routineName = workout.routineName
        cdWorkout.date = workout.date
        cdWorkout.startTime = workout.startTime
        cdWorkout.durationSeconds = Int32(workout.durationSeconds)
        cdWorkout.caloriesBurned = workout.caloriesBurned
        
        // This triggers the setter we wrote in Step 2, encoding the array to Data automatically
        cdWorkout.exercises = workout.exercises
        
        if ctx.hasChanges {
            do {
                try ctx.save()
            } catch {
                print("❌ Failed to save CDCompletedWorkout: \(error)")
            }
        }
    }

    // MARK: - Load
    func loadAll() -> [CompletedWorkout] {
        let request: NSFetchRequest<CDCompletedWorkout> = CDCompletedWorkout.fetchRequest()
        // Sort newest first
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        
        do {
            let results = try Self.context.fetch(request)
            return results.map { $0.toCompletedWorkout() }
        } catch {
            print("❌ Failed to fetch CDCompletedWorkout: \(error)")
            return []
        }
    }

    // MARK: - Queries
    func workout(on date: Date) -> CompletedWorkout? {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return nil }
        
        let request: NSFetchRequest<CDCompletedWorkout> = CDCompletedWorkout.fetchRequest()
        request.predicate = NSPredicate(format: "date >= %@ AND date < %@", startOfDay as NSDate, endOfDay as NSDate)
        request.fetchLimit = 1
        
        guard let result = try? Self.context.fetch(request).first else { return nil }
        return result.toCompletedWorkout()
    }

    func hasCompletedWorkout(on date: Date) -> Bool {
        return workout(on: date) != nil
    }
    
    // MARK: - Migration
    private static func migrateLegacyDataIfNeeded() {
        let key = "completed_workouts_v1"
        guard let data = UserDefaults.standard.data(forKey: key),
              let legacyWorkouts = try? JSONDecoder().decode([CompletedWorkout].self, from: data) else {
            return
        }
        
        print("🔄 Migrating CompletedWorkouts from UserDefaults → Core Data...")
        
        for workout in legacyWorkouts {
            let cdWorkout = CDCompletedWorkout(context: context)
            cdWorkout.id = workout.id
            cdWorkout.routineName = workout.routineName
            cdWorkout.date = workout.date
            cdWorkout.startTime = workout.startTime
            cdWorkout.durationSeconds = Int32(workout.durationSeconds)
            cdWorkout.caloriesBurned = workout.caloriesBurned
            cdWorkout.exercises = workout.exercises
        }
        
        if context.hasChanges {
            try? context.save()
        }
        
        UserDefaults.standard.removeObject(forKey: key)
        print("✅ Migrated \(legacyWorkouts.count) workouts to Core Data")
    }
    
    // MARK: - Seed Mock Data
    func seedMockWorkouts() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Avoid duplicating mock data
        // Only seed historical data if our array has less than 2 workouts
        if loadAll().count > 2 { return }


        // MARK: - Exercises
        let squat = Exercise(name: "Bodyweight Squats", muscleGroup: .legs, equipment: .none, image: "barbell_squat", level: "Beginner", tempo: "2-1-2", form: ["Chest up", "Knees out"], variations: [], commonMistakes: [])
        let pushUps = Exercise(name: "Lat Pulldown", muscleGroup: .chest, equipment: .none, image: "lat_pulldown", level: "Beginner", tempo: "2-0-2", form: ["Straight body line", "Elbows 45°"], variations: [], commonMistakes: [])

        // MARK: - Sets
        let squatSets = [
            ExerciseSet(setNumber: 1, reps: 12, restTimerSeconds: 60, durationSeconds: nil, completionState: .completed),
            ExerciseSet(setNumber: 2, reps: 12, restTimerSeconds: 60, durationSeconds: nil, completionState: .completed)
        ]
        let pushUpSets = [
            ExerciseSet(setNumber: 1, reps: 10, restTimerSeconds: 60, durationSeconds: nil, completionState: .completed)
        ]

        // MARK: - Workout Exercises
        let workoutExercises = [
            WorkoutExercise(id: UUID(), exercise: squat, sets: squatSets, notes: nil),
            WorkoutExercise(id: UUID(), exercise: pushUps, sets: pushUpSets, notes: nil)
        ]

        // MARK: - Completed Workout
        let workoutStart = calendar.date(byAdding: .minute, value: -30, to: Date()) ?? today
        
        // Let's seed 15 days of dummy historical workouts so your calendar looks great
        for dayOffset in 0..<15 {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
            
            // Only workout every other day-ish to look realistic
            if dayOffset % 2 == 0 || dayOffset % 3 == 0 {
                let historicalWorkout = CompletedWorkout(
                    id: UUID(),
                    routineName: "Historical Routine",
                    date: date,
                    startTime: calendar.date(byAdding: .minute, value: -30, to: date) ?? date,
                    durationSeconds: 1800,
                    exercises: workoutExercises,
                    caloriesBurned: 150.0
                )
                save(historicalWorkout)
            }
        }
        print("✅ Seeded CDCompletedWorkout Mock Data")
    }
}
