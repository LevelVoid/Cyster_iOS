//
// MealRecommendationManager.swift
//
// Purpose:
// Manages cached meal recommendations with context fingerprinting to prevent unnecessary AI calls.
//
// Why this exists:
// DietViewController was calling AI every time the tab opened, burning budget unnecessarily.
// This manager caches recommendations and regenerates only when diet or symptom context changes.
//

import Foundation
internal import CoreData
import CryptoKit

/// Posted when meal recommendations are updated (either from cache or fresh generation).
extension Notification.Name {
    static let mealRecommendationsUpdated = Notification.Name("mealRecommendationsUpdated")
}

/// Represents the current state of meal recommendations.
enum MealRecommendationState: Equatable {
    /// Manager has been created but no load attempted yet.
    case idle
    /// Recommendations are being generated.
    case loading
    /// Recommendations are loaded and ready to display.
    case loaded(MealRecommendationOutput)
    /// Generation failed with an error message.
    case failed(String)

    static func == (lhs: MealRecommendationState, rhs: MealRecommendationState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle): return true
        case (.loading, .loading): return true
        case (.failed(let a), .failed(let b)): return a == b
        case (.loaded, .loaded): return true
        default: return false
        }
    }
}

///
/// MealRecommendationManager — single source of truth for today's meal suggestions.
///
/// Public API:
/// - `loadRecommendations()` — returns cached recommendations if context unchanged, else calls AI.
/// - `invalidateCache()` — forces regeneration on next load (called after meal/symptom changes).
///
@MainActor
final class MealRecommendationManager {

    static let shared = MealRecommendationManager()
    private init() {}

    private(set) var state: MealRecommendationState = .idle

    // MARK: - Public API

    ///
    /// Loads today's meal recommendations.
    ///
    /// Parameters: None
    /// Returns: The current meal recommendation state.
    /// Throws: None (errors are captured in state).
    ///
    /// Flow:
    /// 1. Compute current context fingerprint.
    /// 2. Check if cached recommendations exist with matching hash.
    /// 3. If match, return cached. Otherwise, call AI and persist.
    ///
    func loadRecommendations() async -> MealRecommendationState {
        // If already loaded and context hasn't changed, return immediately
        if case .loaded = state {
            let currentHash = await computeContextFingerprint()
            if let cachedHash = fetchCachedHash(), cachedHash == currentHash {
                return state
            }
        }

        state = .loading
        notifyStateChange()

        do {
            let currentHash = await computeContextFingerprint()

            // Check cache first
            if let cached = loadCachedRecommendations(contextHash: currentHash) {
                state = .loaded(cached)
                notifyStateChange()
                return state
            }

            // Cache miss or context changed — generate fresh recommendations
            let context = await SharedContextEngine.shared.buildMealRecommendationContext()
            print("MealRecommendationManager — cache miss, calling AI...")
            let output = try await AIBrain.shared.generateMealRecommendations(context: context)

            // Persist to Core Data
            persistRecommendations(output: output, contextHash: currentHash)

            state = .loaded(output)
            notifyStateChange()
            return state

        } catch {
            let errorMsg = error.localizedDescription
            print("MealRecommendationManager — AI generation failed: \(errorMsg)")
            state = .failed(errorMsg)
            notifyStateChange()
            return state
        }
    }

    ///
    /// Invalidates the cached recommendations, forcing regeneration on next load.
    ///
    /// Parameters: None
    /// Returns: None
    /// Throws: None
    ///
    /// Why this exists:
    /// Called by DietViewController after meal add/edit/delete or symptom changes.
    ///
    func invalidateCache() {
        // Simply clear the state — next load will detect context change
        state = .idle
        print("MealRecommendationManager — cache invalidated")
    }

    // MARK: - Context Fingerprinting

    ///
    /// Computes a deterministic hash of today's meal and symptom context.
    ///
    /// Parameters: None
    /// Returns: SHA256 hash string of the context.
    /// Throws: None
    ///
    /// Why this exists:
    /// Cache key that changes only when meaningful context changes (meals, symptoms, date).
    ///
    /// Included in fingerprint:
    /// - Today's date (YYYY-MM-DD)
    /// - Total protein, carbs, fats, fiber
    /// - Meal count
    /// - Symptom names (sorted)
    ///
    private func computeContextFingerprint() async -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let todayDateString = dateFormatter.string(from: Date())

        // Use SharedContextEngine to fetch today's context (avoiding duplicate Core Data queries)
        let todayContext = SharedContextEngine.shared.fetchTodayContext()

        let totalProtein = todayContext.foodLogs.reduce(0.0) { $0 + $1.protein }
        let totalCarbs = todayContext.foodLogs.reduce(0.0) { $0 + $1.carbs }
        let totalFats = todayContext.foodLogs.reduce(0.0) { $0 + $1.fats }
        let totalFiber = todayContext.foodLogs.reduce(0.0) { $0 + $1.fiber }
        let mealCount = todayContext.foodLogs.count

        // Sort symptoms for deterministic hash
        let symptoms = todayContext.symptoms.sorted()
        let symptomsString = symptoms.joined(separator: ",")

        let contextString = "\(todayDateString)|\(totalProtein)|\(totalCarbs)|\(totalFats)|\(totalFiber)|\(mealCount)|\(symptomsString)"

        // SHA256 hash
        let data = Data(contextString.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }

    // MARK: - Core Data Persistence

    ///
    /// Loads cached recommendations from Core Data if context matches.
    ///
    /// Parameters:
    ///   - contextHash: The current context fingerprint.
    /// Returns: Cached MealRecommendationOutput or nil if no match.
    /// Throws: None
    ///
    private func loadCachedRecommendations(contextHash: String) -> MealRecommendationOutput? {
        guard let context = PersistenceController.shared.container.viewContext as NSManagedObjectContext? else {
            return nil
        }

        let request = NSFetchRequest<NSManagedObject>(entityName: "CDDailyContext")
        request.predicate = NSPredicate(format: "date >= %@ AND date < %@",
                                        Calendar.current.startOfDay(for: Date()) as NSDate,
                                        Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: Date()))! as NSDate)
        request.fetchLimit = 1

        guard let results = try? context.fetch(request),
              let todayContext = results.first as? CDDailyContext else {
            return nil
        }

        // Check if hash matches
        guard let cachedHash = todayContext.value(forKey: "mealRecommendationContextHash") as? String,
              cachedHash == contextHash else {
            print("MealRecommendationManager — context hash mismatch, cache invalid")
            return nil
        }

        // Load cached data
        guard let cachedData = todayContext.value(forKey: "mealRecommendationData") as? Data else {
            return nil
        }

        do {
            let output = try JSONDecoder().decode(MealRecommendationOutput.self, from: cachedData)
            print("MealRecommendationManager — cache HIT, returning cached recommendations")
            return output
        } catch {
            print("MealRecommendationManager — failed to decode cached data: \(error)")
            return nil
        }
    }

    ///
    /// Persists recommendations and context hash to Core Data.
    ///
    /// Parameters:
    ///   - output: The fresh MealRecommendationOutput from AI.
    ///   - contextHash: The context fingerprint to store.
    /// Returns: None
    /// Throws: None
    ///
    private func persistRecommendations(output: MealRecommendationOutput, contextHash: String) {
        guard let context = PersistenceController.shared.container.viewContext as NSManagedObjectContext? else {
            return
        }

        let request = NSFetchRequest<NSManagedObject>(entityName: "CDDailyContext")
        request.predicate = NSPredicate(format: "date >= %@ AND date < %@",
                                        Calendar.current.startOfDay(for: Date()) as NSDate,
                                        Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: Date()))! as NSDate)
        request.fetchLimit = 1

        guard let results = try? context.fetch(request),
              let todayContext = results.first as? CDDailyContext else {
            print("MealRecommendationManager — no CDDailyContext found for today, skipping persist")
            return
        }

        do {
            let data = try JSONEncoder().encode(output)
            todayContext.setValue(data, forKey: "mealRecommendationData")
            todayContext.setValue(contextHash, forKey: "mealRecommendationContextHash")
            todayContext.setValue(Date(), forKey: "mealRecommendationGeneratedAt")

            try context.save()
            print("MealRecommendationManager — recommendations persisted to Core Data")
        } catch {
            print("MealRecommendationManager — failed to persist: \(error)")
        }
    }

    ///
    /// Fetches the cached context hash for today.
    ///
    /// Parameters: None
    /// Returns: The cached hash string or nil.
    /// Throws: None
    ///
    private func fetchCachedHash() -> String? {
        guard let context = PersistenceController.shared.container.viewContext as NSManagedObjectContext? else {
            return nil
        }

        let request = NSFetchRequest<NSManagedObject>(entityName: "CDDailyContext")
        request.predicate = NSPredicate(format: "date >= %@ AND date < %@",
                                        Calendar.current.startOfDay(for: Date()) as NSDate,
                                        Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: Date()))! as NSDate)
        request.fetchLimit = 1

        guard let results = try? context.fetch(request),
              let todayContext = results.first as? CDDailyContext else {
            return nil
        }

        return todayContext.value(forKey: "mealRecommendationContextHash") as? String
    }

    // MARK: - Notification

    private func notifyStateChange() {
        NotificationCenter.default.post(name: .mealRecommendationsUpdated, object: nil)
    }
}
