//
//  UserRoutineDataStore.swift
//  PCOS_App
//
//  Created by SDC-USER on 10/03/26.
//


import Foundation
import CoreData
import UIKit

class UserRoutineDataStore {
    
    static let shared = UserRoutineDataStore()
    private init() {}
    
    // Injectable context for testing
    var injectedContext: NSManagedObjectContext?
    
    private var context: NSManagedObjectContext {
        if let injected = injectedContext {
            return injected
        }
        return (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    }
    
    func save(_ routine: Routine) {
        CDRoutine.from(routine, context: context)
        saveContext()
    }
    
    func loadAll() -> [Routine] {
        let request = CDRoutine.fetchRequest() as NSFetchRequest<CDRoutine>
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        do {
            return try context.fetch(request).map { $0.toRoutine() }
        } catch {
            print("❌ Error loading routines: \(error)")
            return []
        }
    }
    
    func delete(_ routine: Routine) {
        let request = CDRoutine.fetchRequest() as NSFetchRequest<CDRoutine>
        request.predicate = NSPredicate(format: "id == %@", routine.id as CVarArg)
        do {
            for obj in try context.fetch(request) { context.delete(obj) }
            saveContext()
        } catch {
            print("❌ Error deleting routine: \(error)")
        }
    }
    
    private func saveContext() {
        guard context.hasChanges else { return }
        try? context.save()
    }
}
