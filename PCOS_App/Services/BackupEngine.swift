//
// BackupEngine.swift
//
// Purpose:
// Intelligent backup engine that tracks changes with a manifest and uploads opportunistically.
//
// Why this exists:
// Replaces immediate uploads with low-overhead, event-driven backups that minimize
// battery and data usage by coalescing changes and compressing payloads.
//

import UIKit
import Foundation
internal import CoreData
import FirebaseAuth
import CryptoKit

// MARK: - Change Tracking

/// Represents a pending change to be backed up.
struct PendingChange: Codable, Equatable {
    let entity: String
    let recordID: UUID
    var operation: ChangeOperation
    let timestamp: Date
}

/// Type of change operation.
enum ChangeOperation: String, Codable {
    case create
    case update
    case delete
}

/// Upload trigger thresholds per entity type.
struct UploadThresholds {
    static let meals = 5
    static let symptoms = 3
    static let workouts = 1
    static let profile = 0  // Immediate
    static let cycle = 1
}

// MARK: - BackupEngine

///
/// BackupEngine — Intelligent backup with change manifest and opportunistic uploads.
///
/// Public API:
/// - `recordChange(entity:recordID:operation:)` — Records a change to the manifest
/// - `uploadIfNeeded()` — Checks thresholds and uploads if appropriate
/// - `forceUpload()` — Always uploads pending changes
/// - `uploadOnBackground()` — Called when app enters background
///
@MainActor
final class BackupEngine {

    static let shared = BackupEngine()
    private init() {
        loadManifest()
        setupBackgroundObserver()
    }

    // MARK: - Properties

    private var pendingChanges: [UUID: PendingChange] = [:]
    private let userDefaultsKey = "pendingChangesData"
    private let gatewayEndpoint = "https://backup-api-1024644064258.us-central1.run.app"
    private let timeout: TimeInterval = 60.0

    private(set) var isUploading = false
    private(set) var lastBackupDate: Date?

    // MARK: - Change Recording

    ///
    /// Records a change to the backup manifest with coalescing logic.
    ///
    /// Parameters:
    ///   - entity: The Core Data entity name (e.g., "CDFoodLog")
    ///   - recordID: The UUID of the record
    ///   - operation: The type of change (create, update, delete)
    /// Returns: None
    /// Throws: None
    ///
    /// Why coalescing matters:
    /// Multiple edits to the same record collapse into a single operation,
    /// preventing dozens of tiny uploads.
    ///
    func recordChange(entity: String, recordID: UUID, operation: ChangeOperation) {
        let existing = pendingChanges[recordID]
        let newOperation: ChangeOperation?

        // Apply coalescing rules from spec
        switch (existing?.operation, operation) {
        case (.none, .create):
            newOperation = .create
        case (.create, .update):
            newOperation = .create  // Still a create
        case (.update, .update):
            newOperation = .update
        case (.create, .delete):
            // Create then delete = remove from manifest
            pendingChanges.removeValue(forKey: recordID)
            saveManifest()
            return
        case (.update, .delete):
            newOperation = .delete
        case (.delete, .delete):
            newOperation = .delete
        case (.none, .update):
            newOperation = .update
        case (.none, .delete):
            newOperation = .delete
        case (.delete, _):
            newOperation = .delete  // Already deleted
        case (.create, .create), (.update, .create):
            newOperation = existing?.operation  // Keep existing
        }

        if let finalOperation = newOperation {
            pendingChanges[recordID] = PendingChange(
                entity: entity,
                recordID: recordID,
                operation: finalOperation,
                timestamp: Date()
            )
            saveManifest()

            print("BackupEngine — recorded \(finalOperation) for \(entity):\(recordID.uuidString.prefix(8))")
        }
    }

    // MARK: - Public Status Methods

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
        let request = NSFetchRequest<CDUser>(entityName: "CDUser")
        request.fetchLimit = 1

        guard let user = try? context.fetch(request).first else {
            return nil
        }

        return user.lastBackupAt
    }

    // MARK: - Upload Triggers

    ///
    /// Uploads if significant change threshold is reached.
    ///
    /// Parameters: None
    /// Returns: None
    /// Throws: None
    ///
    /// Thresholds:
    /// - Meals: 5 changes
    /// - Symptoms: 3 changes
    /// - Workouts: 1 change
    /// - Profile: immediate
    /// - Cycle: 1 change
    ///
    func uploadIfNeeded() {
        guard !isUploading else { return }
        guard !pendingChanges.isEmpty else { return }

        // Count changes by entity
        var entityCounts: [String: Int] = [:]
        for change in pendingChanges.values {
            entityCounts[change.entity, default: 0] += 1
        }

        // Check thresholds
        var shouldUpload = false

        if let profileCount = entityCounts["CDUser"], profileCount > 0 {
            shouldUpload = true  // Profile changes upload immediately
        } else if let mealCount = entityCounts["CDFoodLog"], mealCount >= UploadThresholds.meals {
            shouldUpload = true
        } else if let symptomCount = entityCounts["CDSymptomLog"], symptomCount >= UploadThresholds.symptoms {
            shouldUpload = true
        } else if let workoutCount = entityCounts["CDCompletedWorkout"], workoutCount >= UploadThresholds.workouts {
            shouldUpload = true
        } else if let cycleCount = entityCounts["CDCycleData"], cycleCount >= UploadThresholds.cycle {
            shouldUpload = true
        }

        if shouldUpload {
            Task {
                try? await performUpload()
            }
        }
    }

    ///
    /// Forces an immediate upload of all pending changes.
    ///
    /// Parameters: None
    /// Returns: None
    /// Throws: BackupError
    ///
    func forceUpload() async throws {
        try await performUpload()
    }

    ///
    /// Called when app enters background — primary upload trigger.
    ///
    /// Parameters: None
    /// Returns: None
    /// Throws: None
    ///
    /// Why this is the best time:
    /// - User finished interacting
    /// - iOS grants execution time
    /// - Natural checkpoint
    ///
    func uploadOnBackground() {
        guard !pendingChanges.isEmpty else { return }
        guard !isUploading else { return }

        Task {
            try? await performUpload()
        }
    }

    // MARK: - Upload Logic

    ///
    /// Performs the actual backup upload with compression.
    ///
    /// Parameters: None
    /// Returns: None
    /// Throws: BackupError
    ///
    private func performUpload() async throws {
        guard !isUploading else { return }
        guard !pendingChanges.isEmpty else { return }

        isUploading = true
        defer { isUploading = false }

        do {
            // 1. Export Core Data
            let payload = try await exportCoreData()

            // 2. Compress payload
            let compressedData = try compressPayload(payload)

            // 3. Generate checksum
            let checksum = generateSHA256(data: compressedData)

            // 4. Get Firebase token
            guard let user = Auth.auth().currentUser else {
                throw BackupError.noUser
            }
            let token = try await user.getIDToken()

            // 5. Upload compressed backup
            try await uploadCompressedBackup(
                data: compressedData,
                checksum: checksum,
                recordCount: countRecords(payload),
                token: token
            )

            // 6. Clear manifest and update timestamp
            pendingChanges.removeAll()
            saveManifest()
            lastBackupDate = Date()
            try await updateLastBackupTimestamp()

            print("BackupEngine — upload completed successfully")

        } catch {
            print("BackupEngine — upload failed: \(error)")
            throw error
        }
    }

    // MARK: - Compression

    ///
    /// Compresses JSON payload using GZIP.
    ///
    /// Parameters:
    ///   - payload: The backup payload to compress
    /// Returns: Compressed data
    /// Throws: BackupError
    ///
    /// Benefits:
    /// - Lower battery usage
    /// - Less mobile data
    /// - Faster uploads
    ///
    private func compressPayload(_ payload: BackupPayload) throws -> Data {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let jsonData = try encoder.encode(payload)

        // Use NSData compression with explicit error handling
        let compressedData: Data?
        do {
            compressedData = try (jsonData as NSData).compressed(using: .lzfse) as Data
        } catch {
            throw BackupError.uploadFailed
        }

        guard let compressed = compressedData else {
            throw BackupError.uploadFailed
        }

        let originalSize = Double(jsonData.count) / 1024.0
        let compressedSize = Double(compressed.count) / 1024.0
        let ratio = (1.0 - compressedSize / originalSize) * 100.0

        print("BackupEngine — compressed \(String(format: "%.1f", originalSize))KB → \(String(format: "%.1f", compressedSize))KB (\(String(format: "%.1f", ratio))% reduction)")

        return compressed
    }

    // MARK: - Checksum

    ///
    /// Generates SHA256 checksum for data integrity verification.
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

    private func countRecords(_ payload: BackupPayload) -> Int {
        return payload.dailyContexts.count +
               payload.cycleData.count +
               payload.customFoods.count +
               payload.routines.count
    }

    // MARK: - Network Operations

    ///
    /// Uploads compressed backup with manifest metadata.
    ///
    /// Parameters:
    ///   - data: Compressed backup data
    ///   - checksum: SHA256 checksum
    ///   - recordCount: Total number of records
    ///   - token: Firebase ID token
    /// Returns: None
    /// Throws: BackupError
    ///
    private func uploadCompressedBackup(data: Data, checksum: String, recordCount: Int, token: String) async throws {
        guard let url = URL(string: "\(gatewayEndpoint)/backup") else {
            throw BackupError.uploadFailed
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
        request.addValue("true", forHTTPHeaderField: "X-Backup-Compressed")
        request.addValue(checksum, forHTTPHeaderField: "X-Backup-Checksum")
        request.addValue("\(recordCount)", forHTTPHeaderField: "X-Backup-Record-Count")
        request.addValue("1", forHTTPHeaderField: "X-Backup-Schema-Version")
        request.timeoutInterval = timeout
        request.httpBody = data

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

    // MARK: - Core Data Export (Reused from BackupManager)

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
            id: cdUser.id ?? UUID(),
            name: cdUser.name ?? "",
            email: cdUser.email,
            dateOfBirth: iso8601.string(from: cdUser.dateOfBirth ?? Date()),
            heightCm: cdUser.heightCm,
            weightKg: cdUser.weightKg,
            activityLevel: cdUser.activityLevel ?? "",
            dietPattern: cdUser.dietPattern ?? "",
            pcosPhenotype: cdUser.pcosPhenotype,
            onboardingCompleted: cdUser.onboardingCompleted,
            createdAt: iso8601.string(from: cdUser.createdAt ?? Date())
        )

        // Export daily contexts
        let dailyContextsRequest = NSFetchRequest<NSManagedObject>(entityName: "CDDailyContext")
        let dailyContexts = (try? context.fetch(dailyContextsRequest)) ?? []

        let backupDailyContexts = dailyContexts.compactMap { context -> BackupDailyContext? in
            guard let cdContext = context as? CDDailyContext else { return nil }

            let foodLogs = (cdContext.foodLogs as? Set<CDFoodLog> ?? []).map { cdLog in
                BackupFoodLog(
                    id: cdLog.id ?? UUID(),
                    name: cdLog.name ?? "",
                    timeStamp: iso8601.string(from: cdLog.timeStamp ?? Date()),
                    servingSize: cdLog.servingSize,
                    proteinContent: cdLog.proteinContent,
                    carbsContent: cdLog.carbsContent,
                    fatsContent: cdLog.fatsContent,
                    fiberContent: cdLog.fiberContent,
                    customCalories: cdLog.customCalories == 0 ? nil : cdLog.customCalories,
                    desc: cdLog.desc,
                    imageURL: cdLog.imageURL,
                    localImage: cdLog.localImage
                )
            }

            let symptomLogs = (cdContext.symptomLogs as? Set<CDSymptomLog> ?? []).map { cdLog in
                BackupSymptomLog(
                    id: cdLog.id ?? UUID(),
                    date: iso8601.string(from: cdLog.date ?? Date()),
                    symptomName: cdLog.symptomName ?? "",
                    symptomCategory: cdLog.symptomCategory ?? "",
                    iconName: cdLog.iconName ?? ""
                )
            }

            let workouts = (cdContext.completedWorkouts as? Set<CDCompletedWorkout> ?? []).map { cdWorkout in
                BackupCompletedWorkout(
                    id: cdWorkout.id ?? UUID(),
                    date: iso8601.string(from: cdWorkout.date ?? Date()),
                    routineName: cdWorkout.routineName ?? "",
                    durationSeconds: cdWorkout.durationSeconds,
                    caloriesBurned: cdWorkout.caloriesBurned
                )
            }

            return BackupDailyContext(
                id: cdContext.id ?? UUID(),
                date: iso8601.string(from: cdContext.date ?? Date()),
                steps: cdContext.steps,
                waterL: cdContext.waterL == 0 ? nil : cdContext.waterL,
                sleepTime: cdContext.sleepTime.map { iso8601.string(from: $0) },
                wakeTime: cdContext.wakeTime.map { iso8601.string(from: $0) },
                sleepQuality: cdContext.sleepQuality == 0 ? nil : cdContext.sleepQuality,
                energyLevel: cdContext.energyLevel == 0 ? nil : cdContext.energyLevel,
                stressLevel: cdContext.stressLevel == 0 ? nil : cdContext.stressLevel,
                cycleDay: cdContext.cycleDay,
                cyclePhase: cdContext.cyclePhase,
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
                id: cdCycle.id ?? UUID(),
                startDate: iso8601.string(from: cdCycle.startDate ?? Date()),
                endDate: cdCycle.endDate.map { iso8601.string(from: $0) },
                periodLength: cdCycle.periodLength,
                cycleLength: cdCycle.cycleLength == 0 ? nil : cdCycle.cycleLength,
                isOvulationConfirmed: cdCycle.isOvulationConfirmed
            )
        }

        // Export custom foods
        let customFoodRequest = NSFetchRequest<NSManagedObject>(entityName: "CDCustomFood")
        let customFoods = (try? context.fetch(customFoodRequest)) ?? []

        let backupCustomFoods = customFoods.compactMap { food -> BackupCustomFood? in
            guard let cdFood = food as? CDCustomFood else { return nil }
            return BackupCustomFood(
                id: cdFood.id ?? UUID(),
                name: cdFood.name ?? "",
                protein: cdFood.protein,
                carbs: cdFood.carbs,
                fat: cdFood.fat,
                fiber: cdFood.fiber,
                calories: cdFood.calories,
                servingSize: cdFood.servingSize,
                category: cdFood.category,
                createdAt: iso8601.string(from: cdFood.createdAt ?? Date())
            )
        }

        // Export routines
        let routineRequest = NSFetchRequest<NSManagedObject>(entityName: "CDRoutine")
        let routines = (try? context.fetch(routineRequest)) ?? []

        let backupRoutines = routines.compactMap { routine -> BackupRoutine? in
            guard let cdRoutine = routine as? CDRoutine else { return nil }
            return BackupRoutine(
                id: cdRoutine.id ?? UUID(),
                name: cdRoutine.name ?? "",
                descriptionText: cdRoutine.descriptionText,
                phase: cdRoutine.phase,
                createdAt: iso8601.string(from: cdRoutine.createdAt ?? Date())
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

        user.lastBackupAt = Date()
        try context.save()
    }

    // MARK: - Manifest Persistence

    ///
    /// Saves the pending changes manifest to UserDefaults.
    ///
    /// Parameters: None
    /// Returns: None
    /// Throws: None
    ///
    private func saveManifest() {
        let changes = Array(pendingChanges.values)
        if let encoded = try? JSONEncoder().encode(changes) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }

    ///
    /// Loads the pending changes manifest from UserDefaults.
    ///
    /// Parameters: None
    /// Returns: None
    /// Throws: None
    ///
    private func loadManifest() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let changes = try? JSONDecoder().decode([PendingChange].self, from: data) else {
            return
        }

        pendingChanges = Dictionary(uniqueKeysWithValues: changes.map { ($0.recordID, $0) })
        print("BackupEngine — loaded \(changes.count) pending changes from manifest")
    }

    // MARK: - Background Observer

    ///
    /// Sets up observer for app entering background.
    ///
    /// Parameters: None
    /// Returns: None
    /// Throws: None
    ///
    private func setupBackgroundObserver() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.uploadOnBackground()
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
