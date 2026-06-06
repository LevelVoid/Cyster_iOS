import CoreData
import UIKit

struct PersistenceController {

    static let shared = PersistenceController()

    private init() {}

    var container: NSPersistentContainer {
        guard let delegate = UIApplication.shared.delegate as? AppDelegate else {
            fatalError("AppDelegate not found — cannot access Core Data container.")
        }
        return delegate.persistentContainer
    }
}
