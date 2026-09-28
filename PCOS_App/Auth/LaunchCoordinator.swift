import UIKit
import FirebaseAuth
internal import CoreData

// MARK: - LaunchCoordinator

/// Centralizes app launch decisions so that no single ViewController
/// scatters routing logic.
///
/// State machine (Milestone 7A):
///   1. Firebase.currentUser?
///        No  → Welcome/Login screen
///   2. Local CDUser exists?
///        Yes → Home (MainTabBarController)
///   3. Cloud backup exists?
///        Yes → Restore automatically → Home
///        No  → Onboarding
///
/// This ensures reinstalls restore data automatically before showing onboarding.
///
final class LaunchCoordinator {

    // MARK: Singleton

    static let shared = LaunchCoordinator()
    private init() {}

    // MARK: - Properties

    private var isCheckingRestore = false

    // MARK: - Root View Controller Resolution

    /// Returns the correct root `UIViewController` based on auth + onboarding state.
    /// Call this from `SceneDelegate` to set `window.rootViewController`.
    ///
    /// Milestone 7A update:
    /// When Firebase session persists but no local CDUser exists (reinstall scenario),
    /// returns a loading screen that automatically checks for and restores backup.
    func resolveRootViewController() -> UIViewController {
        if Auth.auth().currentUser != nil {
            // User is authenticated
            if hasCompletedOnboarding() {
                return makeHomeViewController()
            } else {
                // No local CDUser but Firebase session exists
                // This is a reinstall — check for backup automatically
                return makeRestoreCheckViewController()
            }
        } else {
            // No Firebase user — show Welcome/auth entry point
            return makeOnboardingViewController(resuming: false)
        }
    }

    // MARK: - Post-Auth Navigation

    ///
    /// Called by `TempFirstScreenViewController` after successful authentication.
    ///
    /// Parameters:
    ///   - viewController: The view controller to present from
    /// Returns: None
    /// Throws: None
    ///
    /// Flow (Milestone 7A):
    /// 1. Check if local CDUser exists with completed onboarding
    /// 2. If yes → Navigate to Home
    /// 3. If no → Check cloud backup automatically
    /// 4. If backup exists → Restore silently → Home
    /// 5. If no backup → Begin onboarding
    ///
    func handleSuccessfulAuth(from viewController: UIViewController) {
        if hasCompletedOnboarding() {
            navigateToHome(animated: true)
        } else {
            // Automatically check and restore backup
            checkAndRestoreAutomatically(from: viewController)
        }
    }

    // MARK: - Automatic Restore (Milestone 7A)

    ///
    /// Automatically checks for backup and restores if found.
    /// Only shows onboarding if no backup exists.
    ///
    /// Parameters:
    ///   - viewController: The view controller to present from
    /// Returns: None
    /// Throws: None
    ///
    /// Why automatic:
    /// User should never see onboarding flash if a backup exists.
    /// This creates a seamless reinstall experience.
    ///
    private func checkAndRestoreAutomatically(from viewController: UIViewController) {
        guard !isCheckingRestore else { return }
        isCheckingRestore = true

        // Show loading screen
        let loadingVC = createLoadingViewController()
        viewController.present(loadingVC, animated: false)

        Task { @MainActor in
            defer { isCheckingRestore = false }

            do {
                // Use new RestoreManager
                let restored = try await RestoreManager.shared.restoreIfAvailable()

                loadingVC.dismiss(animated: false) { [weak self] in
                    guard let self = self else { return }

                    if restored {
                        // Backup restored successfully → go to Home
                        print("LaunchCoordinator — backup restored, navigating to Home")
                        self.navigateToHome(animated: true)
                    } else {
                        // No backup found → begin onboarding
                        print("LaunchCoordinator — no backup found, starting onboarding")
                        self.navigateToNameViewController(from: viewController)
                    }
                }
            } catch {
                // Restore failed → offer retry or fresh start
                loadingVC.dismiss(animated: false) { [weak self, weak viewController] in
                    guard let self = self, let viewController = viewController else { return }
                    self.handleRestoreFailure(error: error, from: viewController)
                }
            }
        }
    }

    ///
    /// Handles restore failure by offering retry or fresh start.
    ///
    /// Parameters:
    ///   - error: The error that occurred
    ///   - viewController: The view controller to present from
    /// Returns: None
    /// Throws: None
    ///
    private func handleRestoreFailure(error: Error, from viewController: UIViewController) {
        let alert = UIAlertController(
            title: "Restore Failed",
            message: error.localizedDescription,
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Try Again", style: .default) { [weak self, weak viewController] _ in
            guard let self = self, let viewController = viewController else { return }
            self.checkAndRestoreAutomatically(from: viewController)
        })

        alert.addAction(UIAlertAction(title: "Start Fresh", style: .cancel) { [weak self, weak viewController] _ in
            guard let self = self, let viewController = viewController else { return }
            self.navigateToNameViewController(from: viewController)
        })

        viewController.present(alert, animated: true)
    }

    ///
    /// Creates a loading view controller for restore operations.
    ///
    /// Parameters: None
    /// Returns: A configured loading view controller
    /// Throws: None
    ///
    private func createLoadingViewController() -> UIViewController {
        let vc = UIViewController()
        vc.view.backgroundColor = .systemBackground
        vc.modalPresentationStyle = .fullScreen

        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 20
        stackView.translatesAutoresizingMaskIntoConstraints = false

        let indicator = UIActivityIndicatorView(style: .large)
        indicator.startAnimating()

        let label = UILabel()
        label.text = "Restoring your data..."
        label.font = .systemFont(ofSize: 17, weight: .medium)
        label.textColor = .secondaryLabel
        label.textAlignment = .center

        let subtitle = UILabel()
        subtitle.text = "This usually takes a few seconds."
        subtitle.font = .systemFont(ofSize: 14)
        subtitle.textColor = .tertiaryLabel
        subtitle.textAlignment = .center

        stackView.addArrangedSubview(indicator)
        stackView.addArrangedSubview(label)
        stackView.addArrangedSubview(subtitle)

        vc.view.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: vc.view.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: vc.view.centerYAnchor)
        ])

        return vc
    }

    // MARK: - Onboarding State

    ///
    /// Checks if local CDUser exists and has completed onboarding.
    ///
    /// Parameters: None
    /// Returns: True if user exists locally and onboarding is complete
    /// Throws: None
    ///
    /// Why no CDUser creation:
    /// We defer CDUser creation until after restore check.
    /// If no local CDUser exists, RestoreManager will either:
    /// - Restore it from cloud backup, or
    /// - Let onboarding create a new one
    ///
    func hasCompletedOnboarding() -> Bool {
        guard let uid = Auth.auth().currentUser?.uid else { return false }
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return false }
        let context = appDelegate.viewContext
        let request: NSFetchRequest<CDUser> = CDUser.fetchRequest()
        request.predicate = NSPredicate(format: "firebaseUID == %@", uid)
        request.fetchLimit = 1

        if let cdUser = try? context.fetch(request).first {
            return cdUser.onboardingCompleted
        } else {
            // No local CDUser — return false and let restore check happen
            return false
        }
    }

    // MARK: - Private Factories

    ///
    /// Creates a restore check view controller that automatically checks for backup.
    ///
    /// Parameters: None
    /// Returns: A view controller that shows loading UI and triggers restore
    /// Throws: None
    ///
    /// Why this exists:
    /// When app launches with persisted Firebase session but no local CDUser,
    /// we need to check for backup before deciding to restore or show onboarding.
    ///
    private func makeRestoreCheckViewController() -> UIViewController {
        let vc = RestoreCheckViewController()
        return vc
    }

    private func makeHomeViewController() -> UIViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let tabBarVC = storyboard.instantiateViewController(
            withIdentifier: "MainTabBarController"
        ) as! UITabBarController
        if #available(iOS 18.0, *) {
            tabBarVC.mode = .tabBar
        }
        return tabBarVC
    }

    private func makeOnboardingViewController(resuming: Bool) -> UIViewController {
        let storyboard = UIStoryboard(name: "Onboarding", bundle: nil)

        var step: Int16 = 0
        if resuming {
            if let uid = Auth.auth().currentUser?.uid,
               let appDelegate = UIApplication.shared.delegate as? AppDelegate {
                let context = appDelegate.viewContext
                let request: NSFetchRequest<CDUser> = CDUser.fetchRequest()
                request.predicate = NSPredicate(format: "firebaseUID == %@", uid)
                request.fetchLimit = 1
                if let cdUser = try? context.fetch(request).first {
                    step = cdUser.onboardingStep
                }
            }
            
            let identifier: String
            switch step {
            case 0: identifier = "NameViewController"
            case 1: identifier = "DOBViewController"
            case 2: identifier = "HeightPickerViewController"
            case 3: identifier = "WeightPickerViewController"
            case 4: identifier = "DietTypeViewController"
            case 5: identifier = "MovementTypeViewController"
            case 6: identifier = "PCOSPhenotypeViewController"
            default: identifier = ""
            }

            if !identifier.isEmpty {
                if let vc = storyboard.instantiateViewController(withIdentifier: identifier) as? UIViewController {
                    // Hide back button — there is no prior screen in the restored navigation stack
                    vc.navigationItem.hidesBackButton = true
                    let nav = UINavigationController(rootViewController: vc)
                    nav.setNavigationBarHidden(false, animated: false)
                    return nav
                }
            }
        }

        // Default: show the initial welcome/auth screen
        if let initial = storyboard.instantiateInitialViewController() {
            return initial
        }

        // Fallback — should never happen
        return makeHomeViewController()
    }

    private func navigateToNameViewController(from viewController: UIViewController) {
        let storyboard = UIStoryboard(name: "Onboarding", bundle: nil)
        guard let nameVC = storyboard.instantiateViewController(
            withIdentifier: "NameViewController"
        ) as? NameViewController else { return }

        viewController.navigationController?.pushViewController(nameVC, animated: true)
    }

    func navigateToHome(animated: Bool = true) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first
        else { return }

        let homeVC = makeHomeViewController()

        if animated {
            UIView.transition(
                with: window,
                duration: 0.35,
                options: .transitionCrossDissolve,
                animations: { window.rootViewController = homeVC }
            )
        } else {
            window.rootViewController = homeVC
        }
        window.makeKeyAndVisible()
    }
}
