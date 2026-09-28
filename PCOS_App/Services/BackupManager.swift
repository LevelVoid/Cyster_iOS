//
// BackupManager.swift
//
// Purpose:
// Manages cloud backup and restore operations for the user's Core Data.
//
// Why this exists:
// Allows users to safely backup their PCOS health data to cloud storage
// and restore it when switching devices or reinstalling the app.
//
import UIKit
import Foundation
internal import CoreData
import FirebaseAuth

/// Notification posted when backup status changes.
extension Notification.Name {
    static let backupStatusChanged = Notification.Name("backupStatusChanged")
}

/// Represents the current state of a backup operation.
enum BackupState: Equatable {
    case idle
    case uploading
    case uploaded(Date)
    case downloading
    case restored
    case failed(String)
}

/// Backup error types with user-friendly messages.
enum BackupError: Error, LocalizedError {
    case noInternet
    case unauthorized
    case uploadFailed
    case restoreFailed
    case parseError
    case noCoreDataContext
    case noUser
    
    var errorDescription: String? {
        switch self {
        case .noInternet:
            return "Check your connection"
        case .unauthorized:
            return "Please sign in again"
        case .uploadFailed:
            return "Backup couldn't be completed"
        case .restoreFailed:
            return "We couldn't restore your data"
        case .parseError:
            return "Backup data is corrupted"
        case .noCoreDataContext:
            return "Database error occurred"
        case .noUser:
            return "No user is logged in"
        }
    }
}

/// Codable representation of the restore response from the backend.
struct RestoreResponse: Codable {
    let backupId: String?
    let data: BackupPayload
}

/// Codable representation of the backup payload.
struct BackupPayload: Codable {
    let schemaVersion: Int
    let exportedAt: String
    let user: BackupUser
    let dailyContexts: [BackupDailyContext]
    let cycleData: [BackupCycleData]
    let customFoods: [BackupCustomFood]
    let routines: [BackupRoutine]
}

struct BackupUser: Codable {
    let id: String
    let name: String
    let email: String?
    let dateOfBirth: String
    let heightCm: Double
    let weightKg: Double
    let activityLevel: String
    let dietPattern: String
    let pcosPhenotype: String?
    let onboardingCompleted: Bool
    let createdAt: String
}

struct BackupDailyContext: Codable {
    let id: String
    let date: String
    let steps: Int32
    let waterL: Double?
    let sleepTime: String?
    let wakeTime: String?
    let sleepQuality: Double?
    let energyLevel: Double?
    let stressLevel: Double?
    let cycleDay: Int16
    let cyclePhase: String?
    let foodLogs: [BackupFoodLog]
    let symptomLogs: [BackupSymptomLog]
    let completedWorkouts: [BackupCompletedWorkout]
}

struct BackupFoodLog: Codable {
    let id: String
    let name: String
    let timeStamp: String
    let servingSize: Double
    let proteinContent: Double
    let carbsContent: Double
    let fatsContent: Double
    let fiberContent: Double
    let customCalories: Double?
    let desc: String?
    let imageURL: String?
    let localImage: String?
}

struct BackupSymptomLog: Codable {
    let id: String
    let date: String
    let symptomName: String
    let symptomCategory: String
    let iconName: String
}

struct BackupCompletedWorkout: Codable {
    let id: String
    let date: String
    let routineName: String
    let durationSeconds: Int32
    let caloriesBurned: Double
}

struct BackupCycleData: Codable {
    let id: String
    let startDate: String
    let endDate: String?
    let periodLength: Int16
    let cycleLength: Int16?
    let isOvulationConfirmed: Bool
}

struct BackupCustomFood: Codable {
    let id: String
    let name: String
    let protein: Double
    let carbs: Double
    let fat: Double
    let fiber: Double
    let calories: Int32
    let servingSize: Double
    let category: String?
    let createdAt: String
}

struct BackupRoutine: Codable {
    let id: String
    let name: String
    let descriptionText: String?
    let phase: String?
    let createdAt: String
}

///
/// BackupManager — handles cloud backup and restore operations.
///
/// Public API:
/// - `createBackup()` — exports Core Data to JSON and uploads to cloud.
/// - `restoreBackup()` — downloads latest backup and merges into Core Data.
/// - `getBackupStatus()` — returns last backup timestamp.
///
@MainActor
final class BackupManager {
    
    static let shared = BackupManager()
    private init() {}
    
    private(set) var state: BackupState = .idle
    
    private let gatewayEndpoint = "<backup>"
    private let timeout: TimeInterval = 60.0
    
    // MARK: - Public API
    
    ///
    /// Creates a backup of the user's Core Data and uploads it to cloud storage.
    ///
    /// Parameters: None
    /// Returns: None
    /// Throws: BackupError if backup fails
    ///
    /// Flow:
    /// 1. Export Core Data to versioned JSON
    /// 2. Get Firebase ID token
    /// 3. POST to /backup endpoint
    /// 4. Update CDUser.lastBackupAt
    ///
    func createBackup() async throws {
        state = .uploading
        notifyStateChange()
        
        do {
            // 1. Export Core Data
            let payload = try await exportCoreData()
            
            // 2. Get Firebase token
            guard let user = Auth.auth().currentUser else {
                throw BackupError.noUser
            }
            
            let token = try await user.getIDToken()
            
            // 3. Upload to cloud
            try await uploadBackup(payload: payload, token: token)
            
            // 4. Update lastBackupAt
            try await updateLastBackupTimestamp()
            
            let now = Date()
            state = .uploaded(now)
            notifyStateChange()
            
            print("BackupManager — backup completed successfully")
            
        } catch let error as BackupError {
            state = .failed(error.localizedDescription)
            notifyStateChange()
            throw error
        } catch {
            let mappedError = mapNetworkError(error)
            state = .failed(mappedError.localizedDescription)
            notifyStateChange()
            throw mappedError
        }
    }
    
    ///
    /// Restores the user's data from the latest cloud backup.
    ///
    /// Parameters: None
    /// Returns: None
    /// Throws: BackupError if restore fails
    ///
    /// Flow:
    /// 1. Get Firebase ID token
    /// 2. GET /restore endpoint
    /// 3. Parse JSON payload
    /// 4. Merge into Core Data (idempotent)
    ///
    func restoreBackup() async throws {
        state = .downloading
        notifyStateChange()
        
        do {
            // 1. Get Firebase token
            guard let user = Auth.auth().currentUser else {
                throw BackupError.noUser
            }
            
            let token = try await user.getIDToken()
            
            // 2. Download backup
            let payload = try await downloadBackup(token: token)
            
            // 3. Import into Core Data
            try await importCoreData(payload: payload)
            
            state = .restored
            notifyStateChange()
            
            print("BackupManager — restore completed successfully")
            
        } catch let error as BackupError {
            state = .failed(error.localizedDescription)
            notifyStateChange()
            throw error
        } catch {
            let mappedError = mapNetworkError(error)
            state = .failed(mappedError.localizedDescription)
            notifyStateChange()
            throw mappedError
        }
    }
    
    ///
    /// Returns the timestamp of the last successful backup.
    ///
    /// Parameters: None
    /// Returns: Date of last backup, or nil if never backed up
    /// Throws: None
    ///
    func getLastBackupDate() -> Date? {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return nil
        }
        
        let context = appDelegate.viewContext
        let request = NSFetchRequest<NSManagedObject>(entityName: "CDUser")
        request.fetchLimit = 1
        
        guard let results = try? context.fetch(request),
              let user = results.first as? CDUser else {
            return nil
        }
        
        return user.value(forKey: "lastBackupAt") as? Date
    }
    
    ///
    /// Checks if a backup exists for the current user.
    ///
    /// Parameters: None
    /// Returns: True if backup exists
    /// Throws: BackupError
    ///
    func checkBackupExists() async throws -> Bool {
        guard let user = Auth.auth().currentUser else {
            throw BackupError.noUser
        }
        
        let token = try await user.getIDToken()
        
        guard let url = URL(string: "\(gatewayEndpoint)/backup/status") else {
            throw BackupError.uploadFailed
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = timeout
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let http = response as? HTTPURLResponse else {
            throw BackupError.restoreFailed
        }
        
        if http.statusCode == 401 || http.statusCode == 403 {
            throw BackupError.unauthorized
        }
        
        guard http.statusCode == 200 else {
            return false
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        return json?["backup_exists"] as? Bool ?? false
    }
    
    // MARK: - Core Data Export
    
    ///
    /// Exports all Core Data entities to a versioned JSON payload.
    ///
    /// Parameters: None
    /// Returns: BackupPayload containing all user data
    /// Throws: BackupError if export fails
    ///
    private func exportCoreData() async throws -> BackupPayload {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            throw BackupError.noCoreDataContext
        }
        
        let context = appDelegate.viewContext
        let iso8601 = ISO8601DateFormatter()
        iso8601.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        // Export user
        let userRequest = NSFetchRequest<NSManagedObject>(entityName: "CDUser")
        userRequest.fetchLimit = 1
        guard let userResults = try? context.fetch(userRequest),
              let cdUser = userResults.first as? CDUser else {
            throw BackupError.noUser
        }
        
        let backupUser = BackupUser(
            id: cdUser.value(forKey: "id") as? UUID ?? UUID(),
            name: cdUser.value(forKey: "name") as? String ?? "",
            email: cdUser.value(forKey: "email") as? String,
            dateOfBirth: iso8601.string(from: cdUser.value(forKey: "dateOfBirth") as? Date ?? Date()),
            heightCm: cdUser.value(forKey: "heightCm") as? Double ?? 0,
            weightKg: cdUser.value(forKey: "weightKg") as? Double ?? 0,
            activityLevel: cdUser.value(forKey: "activityLevel") as? String ?? "",
            dietPattern: cdUser.value(forKey: "dietPattern") as? String ?? "",
            pcosPhenotype: cdUser.value(forKey: "pcosPhenotype") as? String,
            onboardingCompleted: cdUser.value(forKey: "onboardingCompleted") as? Bool ?? false,
            createdAt: iso8601.string(from: cdUser.value(forKey: "createdAt") as? Date ?? Date())
        )
        
        // Export daily contexts
        let dailyContextsRequest = NSFetchRequest<NSManagedObject>(entityName: "CDDailyContext")
        let dailyContexts = (try? context.fetch(dailyContextsRequest)) ?? []
        
        let backupDailyContexts = dailyContexts.compactMap { context -> BackupDailyContext? in
            guard let cdContext = context as? CDDailyContext else { return nil }
            
            let foodLogs = (cdContext.value(forKey: "foodLogs") as? Set<NSManagedObject> ?? []).compactMap { log -> BackupFoodLog? in
                guard let cdLog = log as? CDFoodLog else { return nil }
                return BackupFoodLog(
                    id: cdLog.value(forKey: "id") as? UUID ?? UUID(),
                    name: cdLog.value(forKey: "name") as? String ?? "",
                    timeStamp: iso8601.string(from: cdLog.value(forKey: "timeStamp") as? Date ?? Date()),
                    servingSize: cdLog.value(forKey: "servingSize") as? Double ?? 0,
                    proteinContent: cdLog.value(forKey: "proteinContent") as? Double ?? 0,
                    carbsContent: cdLog.value(forKey: "carbsContent") as? Double ?? 0,
                    fatsContent: cdLog.value(forKey: "fatsContent") as? Double ?? 0,
                    fiberContent: cdLog.value(forKey: "fiberContent") as? Double ?? 0,
                    customCalories: cdLog.value(forKey: "customCalories") as? Double,
                    desc: cdLog.value(forKey: "desc") as? String,
                    imageURL: cdLog.value(forKey: "imageURL") as? String,
                    localImage: cdLog.value(forKey: "localImage") as? String
                )
            }
            
            let symptomLogs = (cdContext.value(forKey: "symptomLogs") as? Set<NSManagedObject> ?? []).compactMap { log -> BackupSymptomLog? in
                guard let cdLog = log as? CDSymptomLog else { return nil }
                return BackupSymptomLog(
                    id: cdLog.value(forKey: "id") as? UUID ?? UUID(),
                    date: iso8601.string(from: cdLog.value(forKey: "date") as? Date ?? Date()),
                    symptomName: cdLog.value(forKey: "symptomName") as? String ?? "",
                    symptomCategory: cdLog.value(forKey: "symptomCategory") as? String ?? "",
                    iconName: cdLog.value(forKey: "iconName") as? String ?? ""
                )
            }
            
            let workouts = (cdContext.value(forKey: "completedWorkouts") as? Set<NSManagedObject> ?? []).compactMap { workout -> BackupCompletedWorkout? in
                guard let cdWorkout = workout as? CDCompletedWorkout else { return nil }
                return BackupCompletedWorkout(
                    id: cdWorkout.value(forKey: "id") as? UUID ?? UUID(),
                    date: iso8601.string(from: cdWorkout.value(forKey: "date") as? Date ?? Date()),
                    routineName: cdWorkout.value(forKey: "routineName") as? String ?? "",
                    durationSeconds: cdWorkout.value(forKey: "durationSeconds") as? Int32 ?? 0,
                    caloriesBurned: cdWorkout.value(forKey: "caloriesBurned") as? Double ?? 0
                )
            }
            
            return BackupDailyContext(
                id: cdContext.value(forKey: "id") as? UUID ?? UUID(),
                date: iso8601.string(from: cdContext.value(forKey: "date") as? Date ?? Date()),
                steps: cdContext.value(forKey: "steps") as? Int32 ?? 0,
                waterL: cdContext.value(forKey: "waterL") as? Double,
                sleepTime: (cdContext.value(forKey: "sleepTime") as? Date).map { iso8601.string(from: $0) },
                wakeTime: (cdContext.value(forKey: "wakeTime") as? Date).map { iso8601.string(from: $0) },
                sleepQuality: cdContext.value(forKey: "sleepQuality") as? Double,
                energyLevel: cdContext.value(forKey: "energyLevel") as? Double,
                stressLevel: cdContext.value(forKey: "stressLevel") as? Double,
                cycleDay: cdContext.value(forKey: "cycleDay") as? Int16 ?? 0,
                cyclePhase: cdContext.value(forKey: "cyclePhase") as? String,
                foodLogs: foodLogs,
                symptomLogs: symptomLogs,
                completedWorkouts: workouts
            )
        }
        
        // Export cycle data
        let cycleRequest = NSFetchRequest<NSManagedObject>(entityName: "CDCycleData")
        let cycles = (try? context.fetch(cycleRequest)) ?? []
        
        let backupCycles = cycles.compactMap { cycle -> BackupCycleData? in
            guard let cdCycle = cycle as? CDCycleData else { return nil }
            return BackupCycleData(
                id: cdCycle.value(forKey: "id") as? UUID ?? UUID(),
                startDate: iso8601.string(from: cdCycle.value(forKey: "startDate") as? Date ?? Date()),
                endDate: (cdCycle.value(forKey: "endDate") as? Date).map { iso8601.string(from: $0) },
                periodLength: cdCycle.value(forKey: "periodLength") as? Int16 ?? 0,
                cycleLength: cdCycle.value(forKey: "cycleLength") as? Int16,
                isOvulationConfirmed: cdCycle.value(forKey: "isOvulationConfirmed") as? Bool ?? false
            )
        }
        
        // Export custom foods
        let customFoodRequest = NSFetchRequest<NSManagedObject>(entityName: "CDCustomFood")
        let customFoods = (try? context.fetch(customFoodRequest)) ?? []
        
        let backupCustomFoods = customFoods.compactMap { food -> BackupCustomFood? in
            guard let cdFood = food as? CDCustomFood else { return nil }
            return BackupCustomFood(
                id: cdFood.value(forKey: "id") as? UUID ?? UUID(),
                name: cdFood.value(forKey: "name") as? String ?? "",
                protein: cdFood.value(forKey: "protein") as? Double ?? 0,
                carbs: cdFood.value(forKey: "carbs") as? Double ?? 0,
                fat: cdFood.value(forKey: "fat") as? Double ?? 0,
                fiber: cdFood.value(forKey: "fiber") as? Double ?? 0,
                calories: cdFood.value(forKey: "calories") as? Int32 ?? 0,
                servingSize: cdFood.value(forKey: "servingSize") as? Double ?? 0,
                category: cdFood.value(forKey: "category") as? String,
                createdAt: iso8601.string(from: cdFood.value(forKey: "createdAt") as? Date ?? Date())
            )
        }
        
        // Export routines
        let routineRequest = NSFetchRequest<NSManagedObject>(entityName: "CDRoutine")
        let routines = (try? context.fetch(routineRequest)) ?? []
        
        let backupRoutines = routines.compactMap { routine -> BackupRoutine? in
            guard let cdRoutine = routine as? CDRoutine else { return nil }
            return BackupRoutine(
                id: cdRoutine.value(forKey: "id") as? UUID ?? UUID(),
                name: cdRoutine.value(forKey: "name") as? String ?? "",
                descriptionText: cdRoutine.value(forKey: "descriptionText") as? String,
                phase: cdRoutine.value(forKey: "phase") as? String,
                createdAt: iso8601.string(from: cdRoutine.value(forKey: "createdAt") as? Date ?? Date())
            )
        }
        
        return BackupPayload(
            schemaVersion: 1,
            exportedAt: iso8601.string(from: Date()),
            user: backupUser,
            dailyContexts: backupDailyContexts,
            cycleData: backupCycles,
            customFoods: backupCustomFoods,
            routines: backupRoutines
        )
    }
    
    // MARK: - Network Operations
    
    ///
    /// Uploads backup payload to cloud storage.
    ///
    /// Parameters:
    ///   - payload: The backup data to upload
    ///   - token: Firebase ID token for authentication
    /// Returns: None
    /// Throws: BackupError if upload fails
    ///
    private func uploadBackup(payload: BackupPayload, token: String) async throws {
        guard let url = URL(string: "\(gatewayEndpoint)/backup") else {
            throw BackupError.uploadFailed
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = timeout

        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        request.httpBody = try encoder.encode(payload)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let http = response as? HTTPURLResponse else {
            throw BackupError.uploadFailed
        }
        
        switch http.statusCode {
        case 200...299:
            return
        case 401, 403:
            throw BackupError.unauthorized
        default:
            throw BackupError.uploadFailed
        }
    }
    
    ///
    /// Downloads backup payload from cloud storage.
    ///
    /// Parameters:
    ///   - token: Firebase ID token for authentication
    /// Returns: BackupPayload containing the restored data
    /// Throws: BackupError if download fails
    ///
    private func downloadBackup(token: String) async throws -> BackupPayload {
        guard let url = URL(string: "\(gatewayEndpoint)/restore") else {
            throw BackupError.restoreFailed
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = timeout
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let http = response as? HTTPURLResponse else {
            throw BackupError.restoreFailed
        }
        
        switch http.statusCode {
        case 200...299:
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase

            // First try to decode as wrapped RestoreResponse
            do {
                let response = try decoder.decode(RestoreResponse.self, from: data)
                print("BackupManager — successfully decoded wrapped response")
                return response.data
            } catch let wrapperError {
                print("BackupManager — failed to decode as RestoreResponse: \(wrapperError)")

                // Fallback: try to decode as direct BackupPayload (for backward compatibility)
                do {
                    let payload = try decoder.decode(BackupPayload.self, from: data)
                    print("BackupManager — successfully decoded direct payload")
                    return payload
                } catch let payloadError {
                    print("BackupManager — failed to decode as BackupPayload: \(payloadError)")

                    // Print raw JSON for debugging
                    if let jsonString = String(data: data, encoding: .utf8) {
                        print("BackupManager — Raw response (first 500 chars): \(String(jsonString.prefix(500)))")
                    }
                    throw BackupError.parseError
                }
            }
        case 401, 403:
            throw BackupError.unauthorized
        default:
            throw BackupError.restoreFailed
        }
    }
    
    // MARK: - Core Data Import
    
    ///
    /// Imports backup payload into Core Data with duplicate prevention.
    ///
    /// Parameters:
    ///   - payload: The backup data to import
    /// Returns: None
    /// Throws: BackupError if import fails
    ///
    /// Why this is idempotent:
    /// Uses UUID-based lookups to prevent duplicate record creation.
    ///
    private func importCoreData(payload: BackupPayload) async throws {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            throw BackupError.noCoreDataContext
        }
        
        let context = appDelegate.viewContext
        let iso8601 = ISO8601DateFormatter()
        iso8601.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        // Import daily contexts
        for backupContext in payload.dailyContexts {
            // Check if already exists
            let contextRequest = NSFetchRequest<NSManagedObject>(entityName: "CDDailyContext")
            let contextUUID = UUID(uuidString: backupContext.id) ?? UUID()
            contextRequest.predicate = NSPredicate(format: "id == %@", contextUUID as CVarArg)
            contextRequest.fetchLimit = 1
            
            let existing = try? context.fetch(contextRequest)
            if existing?.isEmpty == false {
                print("BackupManager — skipping duplicate daily context: \(backupContext.id)")
                continue
            }
            
            // Create new daily context
            guard let entity = NSEntityDescription.entity(forEntityName: "CDDailyContext", in: context) else { continue }
            let cdContext = CDDailyContext(entity: entity, insertInto: context)
            
            cdContext.setValue(UUID(uuidString: backupContext.id), forKey: "id")
            cdContext.setValue(iso8601.date(from: backupContext.date), forKey: "date")
            cdContext.setValue(backupContext.steps, forKey: "steps")
            cdContext.setValue(backupContext.waterL, forKey: "waterL")
            cdContext.setValue(backupContext.sleepTime.flatMap { iso8601.date(from: $0) }, forKey: "sleepTime")
            cdContext.setValue(backupContext.wakeTime.flatMap { iso8601.date(from: $0) }, forKey: "wakeTime")
            cdContext.setValue(backupContext.sleepQuality, forKey: "sleepQuality")
            cdContext.setValue(backupContext.energyLevel, forKey: "energyLevel")
            cdContext.setValue(backupContext.stressLevel, forKey: "stressLevel")
            cdContext.setValue(backupContext.cycleDay, forKey: "cycleDay")
            cdContext.setValue(backupContext.cyclePhase, forKey: "cyclePhase")
            
            // Import food logs
            for backupFood in backupContext.foodLogs {
                guard let foodEntity = NSEntityDescription.entity(forEntityName: "CDFoodLog", in: context) else { continue }
                let cdFood = CDFoodLog(entity: foodEntity, insertInto: context)
                
                cdFood.setValue(UUID(uuidString: backupFood.id), forKey: "id")
                cdFood.setValue(backupFood.name, forKey: "name")
                cdFood.setValue(iso8601.date(from: backupFood.timeStamp), forKey: "timeStamp")
                cdFood.setValue(backupFood.servingSize, forKey: "servingSize")
                cdFood.setValue(backupFood.proteinContent, forKey: "proteinContent")
                cdFood.setValue(backupFood.carbsContent, forKey: "carbsContent")
                cdFood.setValue(backupFood.fatsContent, forKey: "fatsContent")
                cdFood.setValue(backupFood.fiberContent, forKey: "fiberContent")
                cdFood.setValue(backupFood.customCalories, forKey: "customCalories")
                cdFood.setValue(backupFood.desc, forKey: "desc")
                cdFood.setValue(backupFood.imageURL, forKey: "imageURL")
                cdFood.setValue(backupFood.localImage, forKey: "localImage")
                cdFood.setValue(cdContext, forKey: "dailyContext")
            }
            
            // Import symptom logs
            for backupSymptom in backupContext.symptomLogs {
                guard let symptomEntity = NSEntityDescription.entity(forEntityName: "CDSymptomLog", in: context) else { continue }
                let cdSymptom = CDSymptomLog(entity: symptomEntity, insertInto: context)
                
                cdSymptom.setValue(UUID(uuidString: backupSymptom.id), forKey: "id")
                cdSymptom.setValue(iso8601.date(from: backupSymptom.date), forKey: "date")
                cdSymptom.setValue(backupSymptom.symptomName, forKey: "symptomName")
                cdSymptom.setValue(backupSymptom.symptomCategory, forKey: "symptomCategory")
                cdSymptom.setValue(backupSymptom.iconName, forKey: "iconName")
                cdSymptom.setValue(cdContext, forKey: "dailyContext")
            }
            
            // Import workouts
            for backupWorkout in backupContext.completedWorkouts {
                guard let workoutEntity = NSEntityDescription.entity(forEntityName: "CDCompletedWorkout", in: context) else { continue }
                let cdWorkout = CDCompletedWorkout(entity: workoutEntity, insertInto: context)
                
                cdWorkout.setValue(UUID(uuidString: backupWorkout.id), forKey: "id")
                cdWorkout.setValue(iso8601.date(from: backupWorkout.date), forKey: "date")
                cdWorkout.setValue(backupWorkout.routineName, forKey: "routineName")
                cdWorkout.setValue(backupWorkout.durationSeconds, forKey: "durationSeconds")
                cdWorkout.setValue(backupWorkout.caloriesBurned, forKey: "caloriesBurned")
                cdWorkout.setValue(cdContext, forKey: "dailyContext")
            }
        }
        
        // Import cycle data
        for backupCycle in payload.cycleData {
            let cycleRequest = NSFetchRequest<NSManagedObject>(entityName: "CDCycleData")
            let cycleUUID = UUID(uuidString: backupCycle.id) ?? UUID()
            cycleRequest.predicate = NSPredicate(format: "id == %@", cycleUUID as CVarArg)
            cycleRequest.fetchLimit = 1
            
            let existing = try? context.fetch(cycleRequest)
            if existing?.isEmpty == false {
                print("BackupManager — skipping duplicate cycle: \(backupCycle.id)")
                continue
            }
            
            guard let entity = NSEntityDescription.entity(forEntityName: "CDCycleData", in: context) else { continue }
            let cdCycle = CDCycleData(entity: entity, insertInto: context)
            
            cdCycle.setValue(UUID(uuidString: backupCycle.id), forKey: "id")
            cdCycle.setValue(iso8601.date(from: backupCycle.startDate), forKey: "startDate")
            cdCycle.setValue(backupCycle.endDate.flatMap { iso8601.date(from: $0) }, forKey: "endDate")
            cdCycle.setValue(backupCycle.periodLength, forKey: "periodLength")
            cdCycle.setValue(backupCycle.cycleLength, forKey: "cycleLength")
            cdCycle.setValue(backupCycle.isOvulationConfirmed, forKey: "isOvulationConfirmed")
        }
        
        // Import custom foods
        for backupFood in payload.customFoods {
            let foodRequest = NSFetchRequest<NSManagedObject>(entityName: "CDCustomFood")
            let foodUUID = UUID(uuidString: backupFood.id) ?? UUID()
            foodRequest.predicate = NSPredicate(format: "id == %@", foodUUID as CVarArg)
            foodRequest.fetchLimit = 1
            
            let existing = try? context.fetch(foodRequest)
            if existing?.isEmpty == false {
                print("BackupManager — skipping duplicate custom food: \(backupFood.id)")
                continue
            }
            
            guard let entity = NSEntityDescription.entity(forEntityName: "CDCustomFood", in: context) else { continue }
            let cdFood = CDCustomFood(entity: entity, insertInto: context)
            
            cdFood.setValue(UUID(uuidString: backupFood.id), forKey: "id")
            cdFood.setValue(backupFood.name, forKey: "name")
            cdFood.setValue(backupFood.protein, forKey: "protein")
            cdFood.setValue(backupFood.carbs, forKey: "carbs")
            cdFood.setValue(backupFood.fat, forKey: "fat")
            cdFood.setValue(backupFood.fiber, forKey: "fiber")
            cdFood.setValue(backupFood.calories, forKey: "calories")
            cdFood.setValue(backupFood.servingSize, forKey: "servingSize")
            cdFood.setValue(backupFood.category, forKey: "category")
            cdFood.setValue(iso8601.date(from: backupFood.createdAt), forKey: "createdAt")
        }
        
        // Import routines
        for backupRoutine in payload.routines {
            let routineRequest = NSFetchRequest<NSManagedObject>(entityName: "CDRoutine")
            let routineUUID = UUID(uuidString: backupRoutine.id) ?? UUID()
            routineRequest.predicate = NSPredicate(format: "id == %@", routineUUID as CVarArg)
            routineRequest.fetchLimit = 1
            
            let existing = try? context.fetch(routineRequest)
            if existing?.isEmpty == false {
                print("BackupManager — skipping duplicate routine: \(backupRoutine.id)")
                continue
            }
            
            guard let entity = NSEntityDescription.entity(forEntityName: "CDRoutine", in: context) else { continue }
            let cdRoutine = CDRoutine(entity: entity, insertInto: context)
            
            cdRoutine.setValue(UUID(uuidString: backupRoutine.id), forKey: "id")
            cdRoutine.setValue(backupRoutine.name, forKey: "name")
            cdRoutine.setValue(backupRoutine.descriptionText, forKey: "descriptionText")
            cdRoutine.setValue(backupRoutine.phase, forKey: "phase")
            cdRoutine.setValue(iso8601.date(from: backupRoutine.createdAt), forKey: "createdAt")
        }
        
        // Save context
        try context.save()
        print("BackupManager — imported \(payload.dailyContexts.count) daily contexts, \(payload.cycleData.count) cycles")
    }
    
    // MARK: - Helper Methods
    
    ///
    /// Updates the lastBackupAt timestamp in CDUser.
    ///
    /// Parameters: None
    /// Returns: None
    /// Throws: BackupError if update fails
    ///
    private func updateLastBackupTimestamp() async throws {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            throw BackupError.noCoreDataContext
        }
        
        let context = appDelegate.viewContext
        let request = NSFetchRequest<NSManagedObject>(entityName: "CDUser")
        request.fetchLimit = 1
        
        guard let results = try? context.fetch(request),
              let user = results.first as? CDUser else {
            throw BackupError.noUser
        }
        
        user.setValue(Date(), forKey: "lastBackupAt")
        try context.save()
    }
    
    ///
    /// Maps network errors to user-friendly BackupError types.
    ///
    /// Parameters:
    ///   - error: The network error
    /// Returns: Mapped BackupError
    /// Throws: None
    ///
    private func mapNetworkError(_ error: Error) -> BackupError {
        let nsError = error as NSError
        
        switch nsError.code {
        case NSURLErrorNotConnectedToInternet, NSURLErrorNetworkConnectionLost:
            return .noInternet
        case NSURLErrorTimedOut:
            return .uploadFailed
        default:
            return .uploadFailed
        }
    }
    
    // MARK: - Notification
    
    private func notifyStateChange() {
        NotificationCenter.default.post(name: .backupStatusChanged, object: nil)
    }
}

// MARK: - UUID Extension

extension BackupUser {
    init(id: UUID, name: String, email: String?, dateOfBirth: String, heightCm: Double, weightKg: Double, activityLevel: String, dietPattern: String, pcosPhenotype: String?, onboardingCompleted: Bool, createdAt: String) {
        self.id = id.uuidString
        self.name = name
        self.email = email
        self.dateOfBirth = dateOfBirth
        self.heightCm = heightCm
        self.weightKg = weightKg
        self.activityLevel = activityLevel
        self.dietPattern = dietPattern
        self.pcosPhenotype = pcosPhenotype
        self.onboardingCompleted = onboardingCompleted
        self.createdAt = createdAt
    }
}

extension BackupDailyContext {
    init(id: UUID, date: String, steps: Int32, waterL: Double?, sleepTime: String?, wakeTime: String?, sleepQuality: Double?, energyLevel: Double?, stressLevel: Double?, cycleDay: Int16, cyclePhase: String?, foodLogs: [BackupFoodLog], symptomLogs: [BackupSymptomLog], completedWorkouts: [BackupCompletedWorkout]) {
        self.id = id.uuidString
        self.date = date
        self.steps = steps
        self.waterL = waterL
        self.sleepTime = sleepTime
        self.wakeTime = wakeTime
        self.sleepQuality = sleepQuality
        self.energyLevel = energyLevel
        self.stressLevel = stressLevel
        self.cycleDay = cycleDay
        self.cyclePhase = cyclePhase
        self.foodLogs = foodLogs
        self.symptomLogs = symptomLogs
        self.completedWorkouts = completedWorkouts
    }
}

extension BackupFoodLog {
    init(id: UUID, name: String, timeStamp: String, servingSize: Double, proteinContent: Double, carbsContent: Double, fatsContent: Double, fiberContent: Double, customCalories: Double?, desc: String?, imageURL: String?, localImage: String?) {
        self.id = id.uuidString
        self.name = name
        self.timeStamp = timeStamp
        self.servingSize = servingSize
        self.proteinContent = proteinContent
        self.carbsContent = carbsContent
        self.fatsContent = fatsContent
        self.fiberContent = fiberContent
        self.customCalories = customCalories
        self.desc = desc
        self.imageURL = imageURL
        self.localImage = localImage
    }
}

extension BackupSymptomLog {
    init(id: UUID, date: String, symptomName: String, symptomCategory: String, iconName: String) {
        self.id = id.uuidString
        self.date = date
        self.symptomName = symptomName
        self.symptomCategory = symptomCategory
        self.iconName = iconName
    }
}

extension BackupCompletedWorkout {
    init(id: UUID, date: String, routineName: String, durationSeconds: Int32, caloriesBurned: Double) {
        self.id = id.uuidString
        self.date = date
        self.routineName = routineName
        self.durationSeconds = durationSeconds
        self.caloriesBurned = caloriesBurned
    }
}

extension BackupCycleData {
    init(id: UUID, startDate: String, endDate: String?, periodLength: Int16, cycleLength: Int16?, isOvulationConfirmed: Bool) {
        self.id = id.uuidString
        self.startDate = startDate
        self.endDate = endDate
        self.periodLength = periodLength
        self.cycleLength = cycleLength
        self.isOvulationConfirmed = isOvulationConfirmed
    }
}

extension BackupCustomFood {
    init(id: UUID, name: String, protein: Double, carbs: Double, fat: Double, fiber: Double, calories: Int32, servingSize: Double, category: String?, createdAt: String) {
        self.id = id.uuidString
        self.name = name
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.fiber = fiber
        self.calories = calories
        self.servingSize = servingSize
        self.category = category
        self.createdAt = createdAt
    }
}

extension BackupRoutine {
    init(id: UUID, name: String, descriptionText: String?, phase: String?, createdAt: String) {
        self.id = id.uuidString
        self.name = name
        self.descriptionText = descriptionText
        self.phase = phase
        self.createdAt = createdAt
    }
}
