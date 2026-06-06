import Foundation
import CoreData

@objc(CDSymptomLog)
public class CDSymptomLog: NSManagedObject {

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
