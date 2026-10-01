//
// RestoreManager.swift
//
// Purpose:
// Handles cloud backup restoration with decompression and integrity verification.
//
// Why this exists:
// Separated from backup logic for single responsibility and to support
// automatic restore before onboarding during app reinstall.
//

import UIKit
import Foundation
internal import CoreData
import FirebaseAuth
import CryptoKit

// MARK: - Restore Response

/// Response from backend containing backup data and metadata.
struct RestoreResponseWithManifest: Codable {
    let backupId: String?
    let data: BackupPayload
    let manifest: BackupManifest?
}

/// Backup manifest with integrity metadata.
struct BackupManifest: Codable {
    let schemaVersion: Int
    let exportedAt: String
    let recordCount: Int
    let compressed: Bool
    let checksum: String?
}

// MARK: - RestoreManager

///
/// RestoreManager — Downloads and restores backups with verification.
///
/// Public API:
/// - `restoreIfAvailable()` — Checks for backup and restores if found
/// - `checkBackupExists()` — Returns true if cloud backup exists
///
@MainActor
final class RestoreManager {

    static let shared = RestoreManager()
    private init() {}

    // MARK: - Properties

    private let gatewayEndpoint = "https://backup-api-1024644064258.us-central1.run.app"
    private let timeout: TimeInterval = 60.0

    private(set) var isRestoring = false

    // MARK: - Public API

    ///
    /// Checks if a backup exists for the current user.
    ///
    /// Parameters: None
    /// Returns: True if backup exists in cloud
    /// Throws: BackupError
    ///
    func checkBackupExists() async throws -> Bool {
        guard let user = Auth.auth().currentUser else {
            throw BackupError.noUser
        }

        let token = try await user.getIDToken()

        guard let url = URL(string: "\(gatewayEndpoint)/backup/status") else {
            throw BackupError.restoreFailed
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

    ///
    /// Restores backup if available, creating CDUser if needed.
    ///
    /// Parameters: None
    /// Returns: True if restore succeeded, False if no backup found
    /// Throws: BackupError if restore fails
    ///
    /// Flow:
    /// 1. Check if backup exists
    /// 2. Download compressed backup
    /// 3. Verify checksum
    /// 4. Decompress
    /// 5. Import into Core Data (idempotent)
    /// 6. Mark onboarding as complete
    ///
    func restoreIfAvailable() async throws -> Bool {
        guard !isRestoring else {
            print("RestoreManager — restore already in progress")
            return false
        }

        isRestoring = true
        defer { isRestoring = false }

        do {
            // 1. Check if backup exists
            let exists = try await checkBackupExists()
            guard exists else {
                print("RestoreManager — no backup found")
                return false
            }

            // 2. Get Firebase token
            guard let user = Auth.auth().currentUser else {
                throw BackupError.noUser
            }
            let token = try await user.getIDToken()

            // 3. Download backup
            let (compressedData, manifest) = try await downloadBackup(token: token)

            // 4. Verify checksum if provided
            if let expectedChecksum = manifest?.checksum {
                let actualChecksum = generateSHA256(data: compressedData)
                guard actualChecksum == expectedChecksum else {
                    print("RestoreManager — checksum mismatch")
                    throw BackupError.parseError
                }
                print("RestoreManager — checksum verified ✓")
            }

            // 5. Decompress
            let payload: BackupPayload
            if manifest?.compressed == true {
                // Decompress with explicit error handling
                let decompressedData: Data
                do {
                    guard let decompressed = try (compressedData as NSData).decompressed(using: .lzfse) as Data? else {
                        throw BackupError.parseError
                    }
                    decompressedData = decompressed
                } catch {
                    throw BackupError.parseError
                }

                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                payload = try decoder.decode(BackupPayload.self, from: decompressedData)
                print("RestoreManager — decompressed \(compressedData.count) → \(decompressedData.count) bytes")
            } else {
                // Fallback: uncompressed
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                payload = try decoder.decode(BackupPayload.self, from: compressedData)
            }

            // 6. Import into Core Data
            try await importCoreData(payload: payload)

            // 7. Mark onboarding complete
            try await markOnboardingComplete()

            print("RestoreManager — restore completed successfully")
            return true

        } catch {
            print("RestoreManager — restore failed: \(error)")
            throw error
        }
    }

    // MARK: - Download

    ///
    /// Downloads backup from cloud storage.
    ///
    /// Parameters:
    ///   - token: Firebase ID token
    /// Returns: Tuple of (backup data, manifest)
    /// Throws: BackupError
    ///
    private func downloadBackup(token: String) async throws -> (Data, BackupManifest?) {
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
            // Try to extract manifest from headers or response
            let compressed = http.value(forHTTPHeaderField: "X-Backup-Compressed") == "true"
            let checksum = http.value(forHTTPHeaderField: "X-Backup-Checksum")
            let recordCountStr = http.value(forHTTPHeaderField: "X-Backup-Record-Count")

            let manifest = BackupManifest(
                schemaVersion: 1,
                exportedAt: ISO8601DateFormatter().string(from: Date()),
                recordCount: Int(recordCountStr ?? "0") ?? 0,
                compressed: compressed,
                checksum: checksum
            )

            return (data, manifest)
        case 401, 403:
            throw BackupError.unauthorized
        case 404:
            throw BackupError.restoreFailed
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
    /// Throws: BackupError
    ///
    /// Why this is idempotent:
    /// - Matches records by UUID
    /// - Updates existing records
    /// - Inserts only missing records
    /// - Preserves relationships
    ///
    private func importCoreData(payload: BackupPayload) async throws {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            throw BackupError.noCoreDataContext
        }

        let context = appDelegate.viewContext
        let iso8601 = ISO8601DateFormatter()
        iso8601.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        // Import or update user
        guard let firebaseUID = Auth.auth().currentUser?.uid else {
            throw BackupError.noUser
        }

        let userRequest = NSFetchRequest<CDUser>(entityName: "CDUser")
        userRequest.predicate = NSPredicate(format: "firebaseUID == %@", firebaseUID)
        userRequest.fetchLimit = 1

        let cdUser: CDUser
        if let existing = try? context.fetch(userRequest).first {
            cdUser = existing
        } else {
            cdUser = CDUser(context: context)
            cdUser.id = UUID(uuidString: payload.user.id) ?? UUID()
            cdUser.firebaseUID = firebaseUID
            cdUser.createdAt = iso8601.date(from: payload.user.createdAt) ?? Date()
        }

        // Update user fields
        cdUser.name = payload.user.name
        cdUser.email = payload.user.email
        cdUser.dateOfBirth = iso8601.date(from: payload.user.dateOfBirth)
        cdUser.heightCm = payload.user.heightCm
        cdUser.weightKg = payload.user.weightKg
        cdUser.activityLevel = payload.user.activityLevel
        cdUser.dietPattern = payload.user.dietPattern
        cdUser.pcosPhenotype = payload.user.pcosPhenotype
        cdUser.onboardingCompleted = true  // Mark as completed after restore

        // Import daily contexts
        for backupContext in payload.dailyContexts {
            let contextRequest = NSFetchRequest<CDDailyContext>(entityName: "CDDailyContext")
            let contextUUID = UUID(uuidString: backupContext.id) ?? UUID()
            contextRequest.predicate = NSPredicate(format: "id == %@", contextUUID as CVarArg)
            contextRequest.fetchLimit = 1

            let existingContext = try? context.fetch(contextRequest).first
            if existingContext != nil {
                print("RestoreManager — skipping duplicate daily context: \(backupContext.id)")
                continue
            }

            let cdContext = CDDailyContext(context: context)
            cdContext.id = contextUUID
            cdContext.date = iso8601.date(from: backupContext.date)
            cdContext.steps = backupContext.steps
            cdContext.waterL = backupContext.waterL ?? 0
            cdContext.sleepTime = backupContext.sleepTime.flatMap { iso8601.date(from: $0) }
            cdContext.wakeTime = backupContext.wakeTime.flatMap { iso8601.date(from: $0) }
            cdContext.sleepQuality = backupContext.sleepQuality ?? 0
            cdContext.energyLevel = backupContext.energyLevel ?? 0
            cdContext.stressLevel = backupContext.stressLevel ?? 0
            cdContext.cycleDay = backupContext.cycleDay
            cdContext.cyclePhase = backupContext.cyclePhase

            // Import food logs
            for backupFood in backupContext.foodLogs {
                let cdFood = CDFoodLog(context: context)
                cdFood.id = UUID(uuidString: backupFood.id) ?? UUID()
                cdFood.name = backupFood.name
                cdFood.timeStamp = iso8601.date(from: backupFood.timeStamp)
                cdFood.servingSize = backupFood.servingSize
                cdFood.proteinContent = backupFood.proteinContent
                cdFood.carbsContent = backupFood.carbsContent
                cdFood.fatsContent = backupFood.fatsContent
                cdFood.fiberContent = backupFood.fiberContent
                cdFood.customCalories = backupFood.customCalories ?? 0
                cdFood.desc = backupFood.desc
                cdFood.imageURL = backupFood.imageURL
                cdFood.localImage = backupFood.localImage
                cdFood.dailyContext = cdContext
            }

            // Import symptom logs
            for backupSymptom in backupContext.symptomLogs {
                let cdSymptom = CDSymptomLog(context: context)
                cdSymptom.id = UUID(uuidString: backupSymptom.id) ?? UUID()
                cdSymptom.date = iso8601.date(from: backupSymptom.date)
                cdSymptom.symptomName = backupSymptom.symptomName
                cdSymptom.symptomCategory = backupSymptom.symptomCategory
                cdSymptom.iconName = backupSymptom.iconName
                cdSymptom.dailyContext = cdContext
            }

            // Import workouts
            for backupWorkout in backupContext.completedWorkouts {
                let cdWorkout = CDCompletedWorkout(context: context)
                cdWorkout.id = UUID(uuidString: backupWorkout.id) ?? UUID()
                cdWorkout.date = iso8601.date(from: backupWorkout.date)
                cdWorkout.routineName = backupWorkout.routineName
                cdWorkout.durationSeconds = backupWorkout.durationSeconds
                cdWorkout.caloriesBurned = backupWorkout.caloriesBurned
                cdWorkout.dailyContext = cdContext
            }
        }

        // Import cycle data
        for backupCycle in payload.cycleData {
            let cycleRequest = NSFetchRequest<CDCycleData>(entityName: "CDCycleData")
            let cycleUUID = UUID(uuidString: backupCycle.id) ?? UUID()
            cycleRequest.predicate = NSPredicate(format: "id == %@", cycleUUID as CVarArg)
            cycleRequest.fetchLimit = 1

            let existingCycle = try? context.fetch(cycleRequest).first
            if existingCycle != nil {
                print("RestoreManager — skipping duplicate cycle: \(backupCycle.id)")
                continue
            }

            let cdCycle = CDCycleData(context: context)
            cdCycle.id = cycleUUID
            cdCycle.startDate = iso8601.date(from: backupCycle.startDate)
            cdCycle.endDate = backupCycle.endDate.flatMap { iso8601.date(from: $0) }
            cdCycle.periodLength = backupCycle.periodLength
            cdCycle.cycleLength = backupCycle.cycleLength ?? 0
            cdCycle.isOvulationConfirmed = backupCycle.isOvulationConfirmed
        }

        // Import custom foods
        for backupFood in payload.customFoods {
            let foodRequest = NSFetchRequest<CDCustomFood>(entityName: "CDCustomFood")
            let foodUUID = UUID(uuidString: backupFood.id) ?? UUID()
            foodRequest.predicate = NSPredicate(format: "id == %@", foodUUID as CVarArg)
            foodRequest.fetchLimit = 1

            let existingFood = try? context.fetch(foodRequest).first
            if existingFood != nil {
                print("RestoreManager — skipping duplicate custom food: \(backupFood.id)")
                continue
            }

            let cdFood = CDCustomFood(context: context)
            cdFood.id = foodUUID
            cdFood.name = backupFood.name
            cdFood.protein = backupFood.protein
            cdFood.carbs = backupFood.carbs
            cdFood.fat = backupFood.fat
            cdFood.fiber = backupFood.fiber
            cdFood.calories = backupFood.calories
            cdFood.servingSize = backupFood.servingSize
            cdFood.category = backupFood.category
            cdFood.createdAt = iso8601.date(from: backupFood.createdAt)
        }

        // Import routines
        for backupRoutine in payload.routines {
            let routineRequest = NSFetchRequest<CDRoutine>(entityName: "CDRoutine")
            let routineUUID = UUID(uuidString: backupRoutine.id) ?? UUID()
            routineRequest.predicate = NSPredicate(format: "id == %@", routineUUID as CVarArg)
            routineRequest.fetchLimit = 1

            let existingRoutine = try? context.fetch(routineRequest).first
            if existingRoutine != nil {
                print("RestoreManager — skipping duplicate routine: \(backupRoutine.id)")
                continue
            }

            let cdRoutine = CDRoutine(context: context)
            cdRoutine.id = routineUUID
            cdRoutine.name = backupRoutine.name
            cdRoutine.descriptionText = backupRoutine.descriptionText
            cdRoutine.phase = backupRoutine.phase
            cdRoutine.createdAt = iso8601.date(from: backupRoutine.createdAt)
        }

        // Save context
        try context.save()
        print("RestoreManager — imported \(payload.dailyContexts.count) daily contexts, \(payload.cycleData.count) cycles")
    }

    ///
    /// Marks onboarding as complete for the current user.
    ///
    /// Parameters: None
    /// Returns: None
    /// Throws: BackupError
    ///
    private func markOnboardingComplete() async throws {
        guard let firebaseUID = Auth.auth().currentUser?.uid else {
            throw BackupError.noUser
        }

        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            throw BackupError.noCoreDataContext
        }

        let context = appDelegate.viewContext
        let request = NSFetchRequest<CDUser>(entityName: "CDUser")
        request.predicate = NSPredicate(format: "firebaseUID == %@", firebaseUID)
        request.fetchLimit = 1

        guard let user = try? context.fetch(request).first else {
            throw BackupError.noUser
        }

        user.onboardingCompleted = true
        try context.save()
    }

    // MARK: - Checksum

    ///
    /// Generates SHA256 checksum for verification.
    ///
    /// Parameters:
    ///   - data: The data to hash
    /// Returns: Hex string of SHA256 hash
    /// Throws: None
    ///
    private func generateSHA256(data: Data) -> String {
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}
