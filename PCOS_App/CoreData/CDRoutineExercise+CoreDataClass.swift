import Foundation
import CoreData

@objc(CDRoutineExercise)
public class CDRoutineExercise: NSManagedObject {

    var exercise: Exercise? {
        get {
            guard let data = exerciseData else { return nil }
            return try? JSONDecoder().decode(Exercise.self, from: data)
        }
        set {
            exerciseData = try? JSONEncoder().encode(newValue)
        }
    }

    func toRoutineExercise() -> RoutineExercise? {
        guard let exercise = exercise else { return nil }
        return RoutineExercise(
            id: id ?? UUID(),
            exercise: exercise,
            numberOfSets: Int(targetSets),
            reps: Int(targetReps),
            weightKg: Int(targetWeight),
            restTimerSeconds: Int(restSecs),
            durationSeconds: durationSecs > 0 ? Int(durationSecs) : nil,
            notes: notes
        )
    }

    @discardableResult
    static func from(_ re: RoutineExercise, context: NSManagedObjectContext) -> CDRoutineExercise {
        let cd = CDRoutineExercise(context: context)
        cd.id = re.id
        cd.exerciseName = re.exercise.name
        cd.targetSets = Int16(re.numberOfSets)
        cd.targetReps = Int16(re.reps)
        cd.targetWeight = Double(re.weightKg)
        cd.restSecs = Int16(re.restTimerSeconds ?? 0)
        cd.durationSecs = Int16(re.durationSeconds ?? 0)
        cd.notes = re.notes
        cd.exercise = re.exercise
        return cd
    }
}
