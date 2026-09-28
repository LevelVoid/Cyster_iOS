//
// AccountDeletionManager.swift
//
// Purpose:
//     Handles complete account deletion including backend cleanup, Firebase removal,
//     and local data wipe per Milestone 8A requirements.
//
// Why this exists:
//     Centralizes all deletion logic to ensure correct ordering and safe failure handling.
//     Never delete Firebase first — backend needs valid auth tokens.
//

import UIKit
import Foundation
internal import CoreData
import FirebaseAuth
import FirebaseCore
import GoogleSignIn
import AuthenticationServices
import RevenueCat

// MARK: - AccountDeletionError

enum AccountDeletionError: LocalizedError {
    case noUser
    case reauthenticationFailed
    case backendDeletionFailed(String)
    case firebaseDeletionFailed
    case localCleanupFailed

    var errorDescription: String? {
        switch self {
        case .noUser:
            return "No authenticated user found."
        case .reauthenticationFailed:
            return "Reauthentication required. Please try again."
        case .backendDeletionFailed(let detail):
            return "Failed to delete cloud data: \(detail)"
        case .firebaseDeletionFailed:
            return "Failed to delete Firebase account. Please try again."
        case .localCleanupFailed:
            return "Failed to clear local data. Please try again."
        }
    }
}

// MARK: - AccountDeletionManager

///
/// AccountDeletionManager — Orchestrates complete account deletion.
///
/// Public API:
/// - `deleteAccount(from:)` — Performs full account deletion with confirmation
///
/// Deletion order (critical):
/// 1. Reauthenticate (if needed)
/// 2. DELETE /account (backend)
/// 3. Delete Firebase account
/// 4. Wipe Core Data
/// 5. Clear sessions
/// 6. Return to onboarding
///
@MainActor
final class AccountDeletionManager {

    // MARK: Singleton

    static let shared = AccountDeletionManager()
    private init() {}

    // MARK: - Properties

    private let gatewayEndpoint = "<backup>"
    private let timeout: TimeInterval = 60.0

    private(set) var isDeletingAccount = false

    // MARK: - Public API

    ///
    /// Deletes the user's account permanently.
    ///
    /// Parameters:
    ///   - viewController: The presenting view controller for reauthentication UI
    /// Returns: None
    /// Throws: AccountDeletionError
    ///
    /// Why this order matters:
    /// Backend deletion requires a valid Firebase token. If we delete Firebase first,
    /// the backend call fails and leaves orphaned data.
    ///
    func deleteAccount(from viewController: UIViewController) async throws {
        guard !isDeletingAccount else {
            print("⚠️ Account deletion already in progress")
            return
        }
        isDeletingAccount = true
        defer { isDeletingAccount = false }

        guard let user = Auth.auth().currentUser else {
            print("❌ No authenticated user found")
            throw AccountDeletionError.noUser
        }

        print("🗑 Account deletion started for user: \(user.uid)")

        // Step 1: Reauthenticate if needed
        // Firebase requires recent authentication for account deletion
        print("📍 Step 1/6: Reauthenticating...")
        try await reauthenticateIfNeeded(user: user, from: viewController)

        // Step 2: Delete backend data (backups, metadata)
        print("📍 Step 2/6: Deleting backend data...")
        try await deleteBackendData(user: user)

        // Step 3: Delete Firebase account
        print("📍 Step 3/6: Deleting Firebase account...")
        try await deleteFirebaseAccount(user: user)

        // Step 4: Wipe local Core Data
        print("📍 Step 4/6: Wiping local data...")
        try await wipeLocalData()

        // Step 5: Clear all sessions
        print("📍 Step 5/6: Clearing sessions...")
        await clearSessions()

        // Step 6: Return to first launch (onboarding)
        print("📍 Step 6/6: Returning to onboarding...")
        await returnToOnboarding()

        print("✅ Account deletion completed successfully!")
    }

    // MARK: - Reauthentication

    ///
    /// Reauthenticates the user if Firebase requires it.
    ///
    /// Parameters:
    ///   - user: The current Firebase user
    ///   - viewController: The presenting view controller
    /// Returns: None
    /// Throws: AccountDeletionError
    ///
    /// Why this exists:
    /// Firebase requires recent authentication (<5 minutes) before allowing
    /// sensitive operations like account deletion.
    ///
    /// Why we don't swallow errors:
    /// If reauthentication fails, Firebase deletion will definitely fail.
    /// Better to fail early with a clear error message.
    ///
    private func reauthenticateIfNeeded(user: User, from viewController: UIViewController) async throws {
        // Get current provider ID
        guard let providerID = user.providerData.first?.providerID else {
            print("⚠️ No provider found, attempting deletion without reauth")
            return
        }

        print("🔐 Provider: \(providerID)")

        if providerID.contains("google") {
            print("🔄 Reauthenticating with Google...")
            try await reauthenticateWithGoogle(user: user, from: viewController)
        } else if providerID.contains("apple") {
            print("🔄 Checking Apple authentication...")
            try await reauthenticateWithApple(user: user, from: viewController)
        } else {
            // Unknown provider — log warning but continue
            print("⚠️ Unknown provider: \(providerID). Attempting deletion without reauth.")
        }
    }

    ///
    /// Reauthenticates with Google Sign-In.
    ///
    /// Parameters:
    ///   - user: The current Firebase user
    ///   - viewController: The presenting view controller
    /// Returns: None
    /// Throws: Error
    ///
    /// Why fresh sign-in:
    /// Firebase requires authentication within the last 5 minutes for account deletion.
    /// We must force a fresh sign-in, not restore cached credentials.
    ///
    private func reauthenticateWithGoogle(user: User, from viewController: UIViewController) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            // Configure Google Sign-In with Firebase client ID
            guard let clientID = FirebaseApp.app()?.options.clientID else {
                print("❌ Firebase client ID not found")
                continuation.resume(throwing: AccountDeletionError.reauthenticationFailed)
                return
            }

            let config = GIDConfiguration(clientID: clientID)
            GIDSignIn.sharedInstance.configuration = config

            // Force fresh sign-in instead of restoring cached credentials
            GIDSignIn.sharedInstance.signIn(withPresenting: viewController) { result, error in
                if let error = error {
                    print("❌ Google sign-in failed: \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                    return
                }

                guard let user = result?.user,
                      let idToken = user.idToken?.tokenString else {
                    print("❌ Failed to get Google ID token")
                    continuation.resume(throwing: AccountDeletionError.reauthenticationFailed)
                    return
                }

                let credential = GoogleAuthProvider.credential(
                    withIDToken: idToken,
                    accessToken: user.accessToken.tokenString
                )

                print("🔄 Reauthenticating Firebase with fresh Google credentials...")
                Auth.auth().currentUser?.reauthenticate(with: credential) { _, error in
                    if let error = error {
                        print("❌ Firebase reauthentication failed: \(error.localizedDescription)")
                        continuation.resume(throwing: error)
                    } else {
                        print("✅ Firebase reauthenticated successfully")
                        continuation.resume()
                    }
                }
            }
        }
    }

    ///
    /// Reauthenticates with Apple Sign-In.
    ///
    /// Parameters:
    ///   - user: The current Firebase user
    ///   - viewController: The presenting view controller
    /// Returns: None
    /// Throws: Error
    ///
    /// Why optional:
    /// Apple Sign-In credentials are valid longer than Google.
    /// Only reauth if Firebase explicitly requires it.
    ///
    private func reauthenticateWithApple(user: User, from viewController: UIViewController) async throws {
        // Apple credentials typically remain valid longer
        // Firebase will throw FIRAuthErrorCodeRequiresRecentLogin if needed
        // For now, skip explicit reauth for Apple
        print("Apple Sign-In: Skipping explicit reauth, Firebase will prompt if needed")
    }

    // MARK: - Backend Deletion

    ///
    /// Deletes user data from backend (Cloud Storage backups).
    ///
    /// Parameters:
    ///   - user: The current Firebase user
    /// Returns: None
    /// Throws: AccountDeletionError
    ///
    /// Why before Firebase:
    /// This call requires a valid Firebase token.
    ///
    private func deleteBackendData(user: User) async throws {
        let token = try await user.getIDToken()

        guard let url = URL(string: "\(gatewayEndpoint)/account") else {
            throw AccountDeletionError.backendDeletionFailed("Invalid endpoint")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = timeout

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw AccountDeletionError.backendDeletionFailed("Invalid response")
        }

        guard http.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw AccountDeletionError.backendDeletionFailed("HTTP \(http.statusCode): \(errorMessage)")
        }

        print("✅ Backend data deleted successfully")
    }

    // MARK: - Firebase Deletion

    ///
    /// Deletes the Firebase account.
    ///
    /// Parameters:
    ///   - user: The current Firebase user
    /// Returns: None
    /// Throws: AccountDeletionError
    ///
    /// Why after backend:
    /// Once this succeeds, the user's auth token becomes invalid.
    ///
    private func deleteFirebaseAccount(user: User) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            user.delete { error in
                if let error = error {
                    let nsError = error as NSError
                    print("❌ Firebase deletion failed: \(error.localizedDescription)")
                    print("   Error code: \(nsError.code)")
                    print("   Error domain: \(nsError.domain)")

                    // Check if it's a "requires recent login" error
                    // AuthErrorCode.requiresRecentLogin.rawValue == 17014
                    if nsError.code == 17014 {
                        print("   ⚠️ This error means reauthentication failed or is too old")
                        continuation.resume(throwing: AccountDeletionError.reauthenticationFailed)
                    } else {
                        continuation.resume(throwing: AccountDeletionError.firebaseDeletionFailed)
                    }
                } else {
                    print("✅ Firebase account deleted successfully")
                    continuation.resume()
                }
            }
        }
    }

    // MARK: - Local Data Cleanup

    ///
    /// Wipes all local Core Data entities.
    ///
    /// Parameters: None
    /// Returns: None
    /// Throws: AccountDeletionError
    ///
    /// Why this exists:
    /// Ensures reinstall does not restore cached data.
    ///
    private func wipeLocalData() async throws {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            throw AccountDeletionError.localCleanupFailed
        }

        let context = appDelegate.viewContext

        // List of all Core Data entities to delete
        let entitiesToDelete: [NSManagedObject.Type] = [
            CDUser.self,
            CDDailyContext.self,
            CDCycleData.self,
            CDFoodLog.self,
            CDSymptomLog.self,
            CDCompletedWorkout.self,
            CDChatMessage.self,
            CDCustomFood.self,
            CDRoutine.self,
            CDRoutineExercise.self,
            CDWorkoutExercise.self,
            CDFoodTag.self
        ]

        for entityType in entitiesToDelete {
            let entityName = String(describing: entityType)
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

            do {
                try context.execute(deleteRequest)
                print("✅ Deleted all \(entityName) entities")
            } catch {
                print("⚠️ Failed to delete \(entityName): \(error.localizedDescription)")
            }
        }

        // Save context
        do {
            try context.save()
            print("✅ Core Data wiped successfully")
        } catch {
            print("❌ Failed to save context after wipe: \(error.localizedDescription)")
            throw AccountDeletionError.localCleanupFailed
        }
    }

    // MARK: - Session Cleanup

    ///
    /// Clears all session data (Firebase, Google, Apple, Keychain, RevenueCat).
    ///
    /// Parameters: None
    /// Returns: None
    /// Throws: None
    ///
    /// Why this exists:
    /// Prevents auto-restore or cached login after deletion.
    ///
    private func clearSessions() async {
        // Clear Firebase Auth
        do {
            try Auth.auth().signOut()
            print("✅ Firebase session cleared")
        } catch {
            print("⚠️ Failed to sign out of Firebase: \(error.localizedDescription)")
        }

        // Clear Google Sign-In
        GIDSignIn.sharedInstance.signOut()
        print("✅ Google Sign-In session cleared")

        // Clear Keychain
        KeychainHelper.delete(key: .firebaseUID)
        KeychainHelper.delete(key: .firebaseIDToken)
        KeychainHelper.delete(key: .refreshToken)
        print("✅ Keychain cleared")

        // Clear RevenueCat identity (future-proof)
        Purchases.shared.logOut { _, _ in
            print("✅ RevenueCat session cleared")
        }

        // Clear UserDefaults backup manifest
        UserDefaults.standard.removeObject(forKey: "pendingChangesData")
        UserDefaults.standard.removeObject(forKey: "lastBackupDate")
        print("✅ UserDefaults cleared")
    }

    // MARK: - Navigation

    ///
    /// Returns the app to onboarding (first launch state).
    ///
    /// Parameters: None
    /// Returns: None
    /// Throws: None
    ///
    /// Why this exists:
    /// User must go through auth and onboarding again.
    ///
    private func returnToOnboarding() async {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else { return }

        let storyboard = UIStoryboard(name: "Onboarding", bundle: nil)
        guard let onboardingVC = storyboard.instantiateInitialViewController() else { return }

        await MainActor.run {
            UIView.transition(
                with: window,
                duration: 0.35,
                options: .transitionCrossDissolve,
                animations: { window.rootViewController = onboardingVC }
            )
            window.makeKeyAndVisible()
        }

        print("✅ Returned to onboarding")
    }
}
