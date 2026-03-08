import Foundation
import CoreData

@objc(CDSymptomLog)
public class CDSymptomLog: NSManagedObject {
    
    /// Convert to SymptomItem for UI consumption
    /// SymptomItem is still needed as a catalog/display struct
    func toSymptomItem() -> SymptomItem {
        SymptomItem(
            name: symptomName ?? "",
            icon: iconName ?? "",
            isSelected: true,
            date: date ?? Date(),
            category: symptomCategory ?? ""
        )
    }
}
