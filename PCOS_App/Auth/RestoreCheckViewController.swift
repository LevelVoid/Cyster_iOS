//
// RestoreCheckViewController.swift
//
// Purpose:
// Automatically checks for cloud backup when app launches with persisted Firebase session.
//
// Why this exists:
// When a user reinstalls the app, Firebase Auth persists via keychain, but there's no
// local CDUser. This screen checks for a cloud backup and restores it automatically
// before showing onboarding, creating a seamless reinstall experience.
//

import UIKit
import FirebaseAuth
internal import CoreData

///
/// RestoreCheckViewController — Shows loading UI and triggers automatic restore check.
///
/// Flow:
/// 1. Display loading screen
/// 2. Check if cloud backup exists
/// 3. If yes → Restore → Navigate to Home
/// 4. If no → Create blank CDUser → Navigate to onboarding
/// 5. If error → Show error with retry option
///
class RestoreCheckViewController: UIViewController {

    // MARK: - UI Components

    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 20
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.startAnimating()
        return indicator
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Checking for your data..."
        label.font = .systemFont(ofSize: 17, weight: .medium)
        label.textColor = .label
        label.textAlignment = .center
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "This will only take a moment."
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        return label
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Start restore check after view appears
        performRestoreCheck()
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = .systemBackground

        stackView.addArrangedSubview(activityIndicator)
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(subtitleLabel)

        view.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stackView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 40),
            stackView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -40)
        ])
    }

    // MARK: - Restore Check

    ///
    /// Performs the automatic restore check.
    ///
    /// Parameters: None
    /// Returns: None
    /// Throws: None
    ///
    @MainActor
    private func performRestoreCheck() {
        Task {
            do {
                // Update UI
                titleLabel.text = "Checking for your data..."
                subtitleLabel.text = "This will only take a moment."

                // Check if backup exists and restore if found
                let restored = try await RestoreManager.shared.restoreIfAvailable()

                if restored {
                    // Backup was restored successfully
                    print("RestoreCheckViewController — backup restored, navigating to Home")
                    await MainActor.run {
                        LaunchCoordinator.shared.navigateToHome(animated: true)
                    }
                } else {
                    // No backup found — create blank user and go to onboarding
                    print("RestoreCheckViewController — no backup found, creating blank user")
                    try createBlankUser()
                    await MainActor.run {
                        navigateToOnboarding()
                    }
                }

            } catch {
                // Restore failed — show error
                await MainActor.run {
                    showError(error)
                }
            }
        }
    }

    ///
    /// Creates a blank CDUser for a new onboarding flow.
    ///
    /// Parameters: None
    /// Returns: None
    /// Throws: Error if creation fails
    ///
    private func createBlankUser() throws {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw BackupError.noUser
        }

        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            throw BackupError.noCoreDataContext
        }

        let context = appDelegate.viewContext

        // Check if user already exists (shouldn't happen, but be safe)
        let request = NSFetchRequest<CDUser>(entityName: "CDUser")
        request.predicate = NSPredicate(format: "firebaseUID == %@", uid)
        request.fetchLimit = 1

        if let existing = try? context.fetch(request).first {
            // User already exists, just return
            return
        }

        // Create new blank user
        let newUser = CDUser(context: context)
        newUser.id = UUID()
        newUser.firebaseUID = uid
        newUser.createdAt = Date()
        newUser.name = ""
        newUser.activityLevel = ""
        newUser.dietPattern = ""
        newUser.email = Auth.auth().currentUser?.email
        newUser.onboardingStep = 0
        newUser.onboardingCompleted = false

        try context.save()
        print("RestoreCheckViewController — created blank CDUser for onboarding")
    }

    ///
    /// Navigates to the first onboarding screen.
    ///
    /// Parameters: None
    /// Returns: None
    /// Throws: None
    ///
    private func navigateToOnboarding() {
        let storyboard = UIStoryboard(name: "Onboarding", bundle: nil)
        guard let nameVC = storyboard.instantiateViewController(
            withIdentifier: "NameViewController"
        ) as? NameViewController else {
            print("RestoreCheckViewController — failed to instantiate NameViewController")
            return
        }

        let navController = UINavigationController(rootViewController: nameVC)
        navController.modalPresentationStyle = .fullScreen

        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return
        }

        UIView.transition(
            with: window,
            duration: 0.35,
            options: .transitionCrossDissolve,
            animations: { window.rootViewController = navController }
        )
        window.makeKeyAndVisible()
    }

    ///
    /// Shows an error alert with retry option.
    ///
    /// Parameters:
    ///   - error: The error that occurred
    /// Returns: None
    /// Throws: None
    ///
    private func showError(_ error: Error) {
        activityIndicator.stopAnimating()
        titleLabel.text = "Restore Failed"
        subtitleLabel.text = error.localizedDescription

        let alert = UIAlertController(
            title: "Restore Failed",
            message: "We couldn't restore your data. You can try again or start fresh.",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Try Again", style: .default) { [weak self] _ in
            self?.activityIndicator.startAnimating()
            self?.performRestoreCheck()
        })

        alert.addAction(UIAlertAction(title: "Start Fresh", style: .cancel) { [weak self] _ in
            // Create blank user and go to onboarding
            do {
                try self?.createBlankUser()
                self?.navigateToOnboarding()
            } catch {
                print("RestoreCheckViewController — failed to create blank user: \(error)")
            }
        })

        present(alert, animated: true)
    }
}
