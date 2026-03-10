import Foundation
import CoreData

@objc(CDRoutine)
public class CDRoutine: NSManagedObject {
    
    func toRoutine() -> Routine {
        let cdExercises = (exercises as? Set<CDRoutineExercise>)?
            .sorted { $0.sortOrder < $1.sortOrder } ?? []
        
        let routineExercises: [RoutineExercise] = cdExercises.compactMap { $0.toRoutineExercise() }
        
        let decodedPhase: Phase? = {
            guard let phaseStr = phase else { return nil }
            switch phaseStr {
            case "menstrual":  return .menstrual
            case "follicular": return .follicular
            case "ovulation":  return .ovulation
            case "luteal":     return .luteal
            default:           return nil
            }
        }()
        
        let decodedType: RoutineType? = {
            guard let typeStr = routineType else { return nil }
            return RoutineType(rawValue: typeStr)
        }()
        
        return Routine(
            id: id ?? UUID(),
            name: name ?? "Untitled",
            exercises: routineExercises,
            createdAt: createdAt ?? Date(),
            thumbnailImageName: thumbnailImage,
            routineTagline: tagline,
            routineDescription: descriptionText,
            phase: decodedPhase,
            routineType: decodedType
        )
    }
    
    @discardableResult
    static func from(_ routine: Routine, context: NSManagedObjectContext) -> CDRoutine {
        let cd = CDRoutine(context: context)
        cd.id = routine.id
        cd.name = routine.name
        cd.createdAt = routine.createdAt
        cd.thumbnailImage = routine.thumbnailImageName
        cd.tagline = routine.routineTagline
        cd.descriptionText = routine.routineDescription
        if let phase = routine.phase {
                   switch phase {
                   case .menstrual:  cd.phase = "menstrual"
                   case .follicular: cd.phase = "follicular"
                   case .ovulation:  cd.phase = "ovulation"
                   case .luteal:     cd.phase = "luteal"
                   case .unknown:    cd.phase = nil
                   }
               }
        cd.routineType = routine.routineType?.rawValue
        
        for (index, re) in routine.exercises.enumerated() {
            let cdExercise = CDRoutineExercise.from(re, context: context)
            cdExercise.sortOrder = Int16(index)
            cdExercise.routine = cd
        }
        
        return cd
    }
}
