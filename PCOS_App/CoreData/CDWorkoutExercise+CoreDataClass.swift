import Foundation
import CoreData

@objc(CDWorkoutExercise)
public class CDWorkoutExercise: NSManagedObject {
    
    // Decode/encode [ExerciseSet] from setsData blob
    var sets: [ExerciseSet] {
        get {
            guard let data = setsData else { return [] }
            return (try? JSONDecoder().decode([ExerciseSet].self, from: data)) ?? []
        }
        set {
            setsData = try? JSONEncoder().encode(newValue)
        }
    }
    
    // Decode/encode Exercise from exerciseData blob
    var exercise: Exercise? {
        get {
            guard let data = exerciseData else { return nil }
            return try? JSONDecoder().decode(Exercise.self, from: data)
        }
        set {
            exerciseData = try? JSONEncoder().encode(newValue)
        }
    }
    
    // Convert to WorkoutExercise struct for UI
    func toWorkoutExercise() -> WorkoutExercise? {
        guard let exercise = exercise else { return nil }
        return WorkoutExercise(
            id: id ?? UUID(),
            exercise: exercise,
            sets: sets,
            notes: notes
        )
    }
    
    // Create from WorkoutExercise struct
    @discardableResult
    static func from(_ we: WorkoutExercise, index: Int, context: NSManagedObjectContext) -> CDWorkoutExercise {
        let cd = CDWorkoutExercise(context: context)
        cd.id = we.id
        cd.exerciseName = we.exercise.name
        cd.sortOrder = Int16(index)
        cd.sets = we.sets
        cd.exercise = we.exercise
        cd.notes = we.notes
        return cd
    }
}
