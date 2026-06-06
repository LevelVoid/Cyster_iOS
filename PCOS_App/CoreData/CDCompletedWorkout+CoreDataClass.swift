import Foundation
import CoreData

@objc(CDCompletedWorkout)
public class CDCompletedWorkout: NSManagedObject {

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
