import UIKit
import HealthKit
import CoreData
import TipKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "PCOS_App")

        let description = NSPersistentStoreDescription()

        if ProcessInfo.processInfo.arguments.contains("-UITestMode") {
            description.url = URL(fileURLWithPath: "/dev/null")
        } else {
            description.url = NSPersistentContainer.defaultDirectoryURL()
                .appendingPathComponent("PCOS_App.sqlite")
        }
        description.shouldInferMappingModelAutomatically = true
        description.shouldMigrateStoreAutomatically = true
        container.persistentStoreDescriptions = [description]

        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                fatalError("Core Data store failed to load: \(error), \(error.userInfo)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true

        return container
    }()

        var viewContext: NSManagedObjectContext {
            return persistentContainer.viewContext
        }

        func saveContext() {
            let context = viewContext
            if context.hasChanges {
                do {
                    try context.save()
                } catch {
                    let nsError = error as NSError

                    print("Core Data save error: \(nsError), \(nsError.userInfo)")
                }
            }
        }

    func applicationWillTerminate(_ application: UIApplication) {

            saveContext()
        }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        if ProcessInfo.processInfo.arguments.contains("-UITestMode") {
            print("🧪 UI Test Mode active - Using in-memory database")
            UIView.setAnimationsEnabled(false)
        }

        HealthKitManager.shared.requestAuthorization { granted, error in
            if let error = error {
                print("HealthKit auth error: \(error.localizedDescription)")
            } else {
                print("HealthKit authorization granted: \(granted)")
            }
        }
        print("📂 Core Data path: \(NSPersistentContainer.defaultDirectoryURL())")
        _ = SymptomDataStore.shared

        ChatPersistenceManager.shared.deleteOldMessages()
        if #available(iOS 17.0, *) {
            try? Tips.configure([
                .displayFrequency(.immediate),
                .datastoreLocation(.applicationDefault)
            ])
        }
        return true
    }

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {

        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {

    }

}

