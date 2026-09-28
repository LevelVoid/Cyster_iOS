import Foundation
internal import CoreData

@objc(CDSymptomLog)
class CDSymptomLog: NSManagedObject {

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
