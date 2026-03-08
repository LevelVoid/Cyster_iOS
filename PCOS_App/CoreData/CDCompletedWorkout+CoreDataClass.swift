import Foundation
import CoreData

@objc(CDCompletedWorkout)
public class CDCompletedWorkout: NSManagedObject {
    
    /// Converts the `exercisesData` (Data) back into our `[WorkoutExercise]` struct array
    var exercises: [WorkoutExercise] {
        get {
            guard let data = exercisesData,
                  let decoded = try? JSONDecoder().decode([WorkoutExercise].self, from: data as Data) else {
                return []
            }
            return decoded
        }
        set {
            if let encoded = try? JSONEncoder().encode(newValue) {
                exercisesData = encoded as NSData
            }
        }
    }
    
    // Bridge to struct for UI consistency
    func toCompletedWorkout() -> CompletedWorkout {
        CompletedWorkout(
            id: id ?? UUID(),
            routineName: routineName ?? "Unknown Routine",
            date: date ?? Date(),
            startTime: startTime ?? Date(),
            durationSeconds: Int(durationSeconds),
            exercises: self.exercises,
            caloriesBurned: caloriesBurned
        )
    }
}
