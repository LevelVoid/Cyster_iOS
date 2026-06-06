import UIKit
import Foundation
enum Equipment: String, Codable, CaseIterable, Sendable {
    case allEquipment,none,barbell,dumbbell,kettlebell,machine,resistanceBand,plate

    var displayName: String {
            switch self {
            case .allEquipment: return "All Equipment"
            case .none: return "No Equipment"
            case .barbell: return "Barbell"
            case .dumbbell: return "Dumbbell"
            case .kettlebell: return "Kettlebell"
            case .machine: return "Machine"
            case .resistanceBand: return "Resistance Band"
            case .plate: return "Plate"
            }
        }
    var displayImage: String {
            switch self {
            case .allEquipment: return "All Equipment"
            case .none: return "No Equipment"
            case .barbell: return "barbell 1"
            case .dumbbell: return "Dumbbell"
            case .kettlebell: return "Kettlebell"
            case .machine: return "Machine"
            case .resistanceBand: return "Resistance Band"
            case .plate: return "Plate"
            }
        }
}
enum MuscleGroup: String, Codable, CaseIterable, Sendable {
    case allMuscles,core, chest, back, legs, shoulders, arms, glutes, cardio, mobility, fullBody

    var displayName: String {
            switch self {
            case .allMuscles: return "All Muscles"
            case .core: return "Core"
            case .chest: return "Chest"
            case .back: return "Back"
            case .legs: return "Legs"
            case .shoulders: return "Shoulders"
            case .arms: return "Arms"
            case .glutes: return "Glutes"
            case .cardio: return "Cardio"
            case .mobility: return "Mobility"
            case .fullBody: return "Full Body"
            }
        }

    var displayImage: String {
            switch self {
            case .allMuscles: return "All Muscles"
            case .core: return "Core"
            case .chest: return "Chest"
            case .back: return "Back"
            case .legs: return "Legs"
            case .shoulders: return "Shoulders"
            case .arms: return "Arms"
            case .glutes: return "Glutes"
            case .cardio: return "Cardio"
            case .mobility: return "Mobility"
            case .fullBody: return "Full Body"
            }
        }

        var isCardio: Bool {
            return self == .cardio
        }
}
struct Exercise: Identifiable, Codable, Sendable {
    var id: UUID
    let name: String
    let muscleGroup: MuscleGroup          
    let equipment: Equipment
    let image: String?
    let instructions: String?

    let gifUrl: String?                   

    let level: String                     
    let tempo: String                     
    let form: [String]                    
    let variations: [String]              
    let commonMistakes: [String]          

    init(
        id: UUID = UUID(),
        name: String,
        muscleGroup: MuscleGroup,
        equipment: Equipment,
        image: String? = nil,
        instructions: String? = nil,
        gifUrl: String? = nil,
        level: String,
        tempo: String,
        form: [String],
        variations: [String],
        commonMistakes: [String]
    ) {
        self.id = id
        self.name = name
        self.muscleGroup = muscleGroup
        self.equipment = equipment
        self.image = image
        self.instructions = instructions
        self.gifUrl = gifUrl
        self.level = level
        self.tempo = tempo
        self.form = form
        self.variations = variations
        self.commonMistakes = commonMistakes
    }

    var isCardio: Bool {
        muscleGroup.isCardio
    }

    var isYoga: Bool {
        muscleGroup == .mobility
    }

    var isTimeBased: Bool {
        isCardio || isYoga
    }

    var gifImage: UIImage? {
            guard let gifName = gifUrl else { return nil }
            return GIFManager.shared.gif(named: gifName)
        }
}

struct RoutineExercise: Codable, Identifiable {
    var id: UUID
    var exercise: Exercise
    var numberOfSets: Int
    var reps: Int
    var weightKg :  Int
    var restTimerSeconds: Int?

    var durationSeconds: Int?
    var notes: String?
    init (id: UUID = UUID(),
             exercise: Exercise,
             numberOfSets: Int? = nil,
             reps: Int? = nil,
             weightKg: Int = 0,
             restTimerSeconds: Int? = nil,
             durationSeconds: Int? = nil,
             notes: String? = nil) {

            self.id = id
            self.exercise = exercise
            self.weightKg = weightKg
            self.notes = notes

            if exercise.isTimeBased {
                self.numberOfSets = 1
                self.reps = 0
                self.restTimerSeconds = nil
                let rawDuration = durationSeconds ?? (exercise.isYoga ? 180 : 600)
                self.durationSeconds = exercise.isYoga ? min(rawDuration, 180) : rawDuration
            } else {
                self.numberOfSets = numberOfSets ?? 3
                self.reps = reps ?? 10
                self.restTimerSeconds = restTimerSeconds ?? 60  
                self.durationSeconds = nil
            }
        }

    func generateWorkoutExercise() -> WorkoutExercise {
        if exercise.isTimeBased {

                   let cardioSet = ExerciseSet(
                       setNumber: 1,
                       reps: 0,

                       restTimerSeconds: nil,
                       durationSeconds: durationSeconds,

                   )

                   return WorkoutExercise(
                       id: id,
                       exercise: exercise,
                       sets: [cardioSet],
                       notes: notes
                   )
               } else {

                   let sets = (1...numberOfSets).map {
                       ExerciseSet(
                           setNumber: $0,
                           reps: reps,

                           restTimerSeconds: restTimerSeconds,
                           durationSeconds: nil,

                       )
                   }

                   return WorkoutExercise(
                       id: id,
                       exercise: exercise,
                       sets: sets,
                       notes: notes
                   )
               }
           }

}

struct Card {
    let name: String
    let image: String
    var toBeDone: Double
    var done: Double?
    var unit: String?
    var tintColor: UIColor {
            switch name.lowercased() {
            case "cals burnt":
                return UIColor(hex: "#FF5C5C")
            case "steps":
                return UIColor(hex: "#3D8BFF")
            case "duration":
                return UIColor(hex: "#00D4C8")
            default:
                return .systemBlue
            }
        }
}

struct ExerciseSet: Codable, Identifiable {
    var id = UUID()
    var setNumber: Int
    var reps: Int

    var restTimerSeconds: Int?
    var durationSeconds: Int? 
    var elapsedSeconds: Int? = 0 
    var completionState: SetCompletionState = .notStarted
}
enum SetCompletionState: String, Codable{
    case notStarted
    case completed
    case skipped
}

struct WorkoutExercise: Codable, Identifiable {
    var id: UUID
    var exercise: Exercise
    var sets: [ExerciseSet]
    var notes: String?
}
enum RoutineType: String, Codable {
    case yoga
    case strength
    case mixed
}

struct Routine: Identifiable, Codable {
    var id: UUID
    var name: String
    var exercises: [RoutineExercise]
    var createdAt: Date = Date()
    var thumbnailImageName: String?
    var routineTagline: String?
    var routineDescription: String?
    var phase: Phase?              
    var routineType: RoutineType?
    var totalExercises: Int { exercises.count }

    var totalSets: Int {
        exercises.reduce(0) { total, ex in

            return total + (ex.exercise.isTimeBased ? 1 : ex.numberOfSets)
        }
    }

    var estimatedDurationSeconds: Int {
        exercises.reduce(0) { total, ex in
            if ex.exercise.isTimeBased {

                return total + (ex.durationSeconds ?? 0)
            } else {

                let activePerSet = ex.reps * 4 
                let rest = ex.restTimerSeconds ?? 0
                return total + (activePerSet + rest) * ex.numberOfSets
            }
        }
    }

    var formattedDuration: String {
        let minutes = estimatedDurationSeconds / 60
        if minutes > 60 {
            return "\(minutes/60)h \(minutes%60)m"
        }
        return "\(minutes) min"
    }
}

struct ActiveWorkout {
    var id = UUID()
    var routine: Routine                    
    var exercises: [WorkoutExercise]        

    var startTime: Date = Date()
    var endTime: Date?
    var durationSeconds: Int = 0            

    mutating func finish() {
        endTime = Date()
        durationSeconds = Int(endTime!.timeIntervalSince(startTime))

    }
}
struct CompletedWorkout: Codable {
    var id = UUID()
    var routineName: String
    var date: Date
    var startTime: Date        
    var durationSeconds: Int
    var exercises: [WorkoutExercise]
    var caloriesBurned: Double = 0  
}

class WorkoutSessionManager {
    static let shared = WorkoutSessionManager()
    private init() {}
    var activeWorkout: ActiveWorkout?
}

struct RoutineImageProvider {
    static let images = [

        "routine_911", "routine_1011", "routine_1111",
        "routine_1211", "routine_1311", "routine_1411",
        "routine_1511"
    ]

    static func random() -> String {
        images.randomElement()!
    }

    static func uniqueImage(usedImages: [String]) -> String {
        let available = images.filter { !usedImages.contains($0) }
        return available.randomElement() ?? images.randomElement()!
    }
}
struct ResumePoint {
    let exerciseIndex: Int
    let setIndex: Int
}

extension CompletedWorkout {
    func resumePoint() -> ResumePoint? {
        for (exIndex, exercise) in exercises.enumerated() {

            if exercise.exercise.isTimeBased {
                if exercise.sets.first?.completionState != .completed {
                    return ResumePoint(exerciseIndex: exIndex, setIndex: 0)
                }
                continue
            }

            for (setIndex, set) in exercise.sets.enumerated() {
                if set.completionState != .completed {
                    return ResumePoint(exerciseIndex: exIndex, setIndex: setIndex)
                }
            }
        }
        return nil 
    }

}
extension ActiveWorkout {
    static func resume(
        routine: Routine,
        completedWorkout: CompletedWorkout
    ) -> ActiveWorkout {

        ActiveWorkout(
            routine: routine,
            exercises: completedWorkout.exercises,
            startTime: Date()
        )
    }
}
extension CompletedWorkout {

    var isFullyCompleted: Bool {
        for exercise in exercises {
            for set in exercise.sets {
                if set.completionState != .completed {
                    return false
                }
            }
        }
        return true
    }
}

