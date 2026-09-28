//
// CoreDataBackupObserver.swift
//
// Purpose:
// Observes Core Data changes and triggers backup engine automatically.
//
// Why this exists:
// Eliminates manual backup calls scattered throughout the app.
// Changes are recorded in the manifest, and uploads happen opportunistically.
//

import Foundation
internal import CoreData
import UIKit

///
/// CoreDataBackupObserver — Automatically records changes to BackupEngine.
///
/// How it works:
/// 1. Observes NSManagedObjectContextObjectsDidChange notification
/// 2. Identifies inserted, updated, and deleted objects
/// 3. Records each change to BackupEngine with proper operation type
/// 4. BackupEngine decides when to upload based on thresholds
///
@MainActor
final class CoreDataBackupObserver {

    static let shared = CoreDataBackupObserver()
    private init() {}

    private var isObserving = false

    // MARK: - Start/Stop Observation

    ///
    /// Starts observing Core Data changes.
    ///
    /// Parameters: None
    /// Returns: None
    /// Throws: None
    ///
    /// Call this once from AppDelegate after Core Data stack is ready.
    ///
    func startObserving() {
        guard !isObserving else { return }
        isObserving = true

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(contextDidChange(_:)),
            name: NSNotification.Name.NSManagedObjectContextObjectsDidChange,
            object: nil
        )

        print("CoreDataBackupObserver — started observing")
    }

    ///
    /// Stops observing Core Data changes.
    ///
    /// Parameters: None
    /// Returns: None
    /// Throws: None
    ///
    func stopObserving() {
        guard isObserving else { return }
        isObserving = false

        NotificationCenter.default.removeObserver(
            self,
            name: NSNotification.Name.NSManagedObjectContextObjectsDidChange,
            object: nil
        )

        print("CoreDataBackupObserver — stopped observing")
    }

    // MARK: - Change Handling

    ///
    /// Called when managed object context changes.
    ///
    /// Parameters:
    ///   - notification: The change notification
    /// Returns: None
    /// Throws: None
    ///
    @objc private func contextDidChange(_ notification: Notification) {
        guard let context = notification.object as? NSManagedObjectContext else { return }
        guard context == (UIApplication.shared.delegate as? AppDelegate)?.viewContext else { return }

        // Process inserted objects
        if let inserted = notification.userInfo?[NSInsertedObjectsKey] as? Set<NSManagedObject> {
            for object in inserted {
                recordChange(for: object, operation: .create)
            }
        }

        // Process updated objects
        if let updated = notification.userInfo?[NSUpdatedObjectsKey] as? Set<NSManagedObject> {
            for object in updated {
                recordChange(for: object, operation: .update)
            }
        }

        // Process deleted objects
        if let deleted = notification.userInfo?[NSDeletedObjectsKey] as? Set<NSManagedObject> {
            for object in deleted {
                recordChange(for: object, operation: .delete)
            }
        }

        // Check if upload is needed based on thresholds
        BackupEngine.shared.uploadIfNeeded()
    }

    ///
    /// Records a change to the backup engine.
    ///
    /// Parameters:
    ///   - object: The managed object that changed
    ///   - operation: The type of change (create, update, delete)
    /// Returns: None
    /// Throws: None
    ///
    private func recordChange(for object: NSManagedObject, operation: ChangeOperation) {
        let entityName = object.entity.name ?? "Unknown"

        // Only track entities we backup
        let trackedEntities = [
            "CDUser",
            "CDDailyContext",
            "CDFoodLog",
            "CDSymptomLog",
            "CDCompletedWorkout",
            "CDCycleData",
            "CDCustomFood",
            "CDRoutine"
        ]

        guard trackedEntities.contains(entityName) else { return }

        // Extract UUID
        guard let recordID = extractUUID(from: object) else {
            print("CoreDataBackupObserver — no UUID for \(entityName)")
            return
        }

        // Record change
        BackupEngine.shared.recordChange(
            entity: entityName,
            recordID: recordID,
            operation: operation
        )
    }

    ///
    /// Extracts UUID from a managed object.
    ///
    /// Parameters:
    ///   - object: The managed object
    /// Returns: The UUID, or nil if not found
    /// Throws: None
    ///
    private func extractUUID(from object: NSManagedObject) -> UUID? {
        // Most entities have an "id" field
        if let id = object.value(forKey: "id") as? UUID {
            return id
        }

        // Fallback: try to get objectID (not ideal for tracking across devices)
        // For deleted objects, we might not have the id anymore
        // In that case, we use a hash of the objectID
        let objectID = object.objectID
        if !objectID.isTemporaryID {
            // Use the persistent ID's URI representation
            let uriString = objectID.uriRepresentation().absoluteString
            return UUID(uuidString: uriString.md5Hash) ?? UUID()
        }

        return nil
    }
}

// MARK: - String MD5 Extension

extension String {
    var md5Hash: String {
        // Simple hash for objectID → UUID mapping
        // Not cryptographically secure, just for stable ID generation
        let data = Data(self.utf8)
        let hash = data.reduce(0) { ($0 &+ UInt64($1)) % UInt64.max }
        let uuidString = String(format: "%08x-0000-0000-0000-%012x",
                               hash >> 32,
                               hash & 0xFFFFFFFF)
        return uuidString
    }
}
