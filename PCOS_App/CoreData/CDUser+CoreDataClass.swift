import Foundation
import CoreData

@objc(CDUser)
public class CDUser: NSManagedObject {

    var calculatedBMI: Double {
        let heightInMeters = heightCm / 100
        guard heightInMeters > 0 else { return 0 }
        return weightKg / (heightInMeters * heightInMeters)
    }

    var bmiCategory: String {
        switch calculatedBMI {
        case ..<18.5:  return "underweight"
        case 18.5..<25: return "normal"
        case 25..<30:   return "overweight"
        default:        return "obese"
        }
    }

    var age: Int {
        guard let dob = dateOfBirth else { return 0 }
        return Calendar.current.dateComponents([.year], from: dob, to: Date()).year ?? 0
    }
}
