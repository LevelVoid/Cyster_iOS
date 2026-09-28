import UIKit
import FirebaseAuth
import CoreData

// MARK: - LaunchCoordinator

/// Centralizes app launch decisions so that no single ViewController
/// scatters routing logic.
///
/// State machine:
///   Firebase.currentUser?
///     No  → Welcome screen
///     Yes → hasCompletedOnboarding?
///               No  → Resume onboarding at correct step
///               Yes → Home (MainTabBarController)
final class LaunchCoordinator {

    // MARK: Singleton

    static let shared = LaunchCoordinator()
    private init() {}

    // MARK: - Root View Controller Resolution

    /// Returns the correct root `UIViewController` based on auth + onboarding state.
    /// Call this from `SceneDelegate` to set `window.rootViewController`.
    func resolveRootViewController() -> UIViewController {
        if Auth.auth().currentUser != nil {
            // User is authenticated
            if hasCompletedOnboarding() {
                return makeHomeViewController()
            } else {
                // Resume at the earliest incomplete onboarding step
                return makeOnboardingViewController(resuming: true)
            }
        } else {
            // No Firebase user — show Welcome/auth entry point
            return makeOnboardingViewController(resuming: false)
        }
    }

    // MARK: - Post-Auth Navigation

    /// Called by `TempFirstScreenViewController` after successful authentication.
    /// Pushes `NameViewController` (new user) or replaces root with Home (returning user).
    func handleSuccessfulAuth(from viewController: UIViewController) {
        if hasCompletedOnboarding() {
            navigateToHome(animated: true)
        } else {
            // Check if this is a fresh install with a backup available
            checkAndOfferRestore(from: viewController)
        }
    }
    
    // MARK: - Backup Restore on Fresh Install
    
    ///
    /// Checks if a backup exists and offers to restore it before onboarding.
    ///
    /// Parameters:
    ///   - viewController: The view controller to present alerts from
    /// Returns: None
    /// Throws: None
    ///
    /// Why this exists:
    /// When a user reinstalls the app or logs in from a new device, we should
    /// offer to restore their backup before they go through onboarding again.
    ///
    private func checkAndOfferRestore(from viewController: UIViewController) {
        Task { @MainActor in
            do {
                let backupExists = try await BackupManager.shared.checkBackupExists()
                
                if backupExists {
                    // Show restore prompt
                    let alert = UIAlertController(
                        title: "Backup Found",
                        message: "We found a backup of your data. Would you like to restore it?",
                        preferredStyle: .alert
                    )
                    
                    alert.addAction(UIAlertAction(title: "Restore", style: .default) { [weak self, weak viewController] _ in
                        guard let self = self, let viewController = viewController else { return }
                        self.performRestoreAndNavigate(from: viewController)
                    })
                    
                    alert.addAction(UIAlertAction(title: "Start Fresh", style: .cancel) { [weak self, weak viewController] _ in
                        guard let self = self, let viewController = viewController else { return }
                        self.navigateToNameViewController(from: viewController)
                    })
                    
                    viewController.present(alert, animated: true)
                } else {
                    // No backup, proceed to onboarding
                    navigateToNameViewController(from: viewController)
                }
            } catch {
                // If check fails, just proceed to onboarding
                print("LaunchCoordinator — backup check failed: \(error)")
                navigateToNameViewController(from: viewController)
            }
        }
    }
    
    ///
    /// Performs the backup restore and navigates to home on success.
    ///
    /// Parameters:
    ///   - viewController: The view controller to present alerts from
    /// Returns: None
    /// Throws: None
    ///
    private func performRestoreAndNavigate(from viewController: UIViewController) {
        // Show loading indicator
        let loadingAlert = UIAlertController(
            title: "Restoring Backup",
            message: "Please wait while we restore your data...",
            preferredStyle: .alert
        )
        
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.startAnimating()
        
        loadingAlert.view.addSubview(indicator)
        NSLayoutConstraint.activate([
            indicator.centerXAnchor.constraint(equalTo: loadingAlert.view.centerXAnchor),
            indicator.bottomAnchor.constraint(equalTo: loadingAlert.view.bottomAnchor, constant: -20)
        ])
        
        viewController.present(loadingAlert, animated: true)
        
        Task { @MainActor in
            do {
                try await BackupManager.shared.restoreBackup()
                
                // Update user onboarding status to completed
                if let uid = Auth.auth().currentUser?.uid,
                   let appDelegate = UIApplication.shared.delegate as? AppDelegate {
                    let context = appDelegate.viewContext
                    let request: NSFetchRequest<CDUser> = CDUser.fetchRequest()
                    request.predicate = NSPredicate(format: "firebaseUID == %@", uid)
                    request.fetchLimit = 1
                    
                    if let cdUser = try? context.fetch(request).first {
                        cdUser.onboardingCompleted = true
                        try? context.save()
                    }
                }
                
                loadingAlert.dismiss(animated: true) { [weak self] in
                    guard let self = self else { return }
                    
                    let successAlert = UIAlertController(
                        title: "Restore Complete",
                        message: "Your data has been restored successfully!",
                        preferredStyle: .alert
                    )
                    
                    successAlert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
                        self?.navigateToHome(animated: true)
                    })
                    
                    viewController.present(successAlert, animated: true)
                }
            } catch {
                loadingAlert.dismiss(animated: true) { [weak self, weak viewController] in
                    guard let self = self, let viewController = viewController else { return }
                    
                    let errorAlert = UIAlertController(
                        title: "Restore Failed",
                        message: error.localizedDescription,
                        preferredStyle: .alert
                    )
                    
                    errorAlert.addAction(UIAlertAction(title: "Try Again", style: .default) { [weak self, weak viewController] _ in
                        guard let self = self, let viewController = viewController else { return }
                        self.performRestoreAndNavigate(from: viewController)
                    })
                    
                    errorAlert.addAction(UIAlertAction(title: "Start Fresh", style: .cancel) { [weak self, weak viewController] _ in
                        guard let self = self, let viewController = viewController else { return }
                        self.navigateToNameViewController(from: viewController)
                    })
                    
                    viewController.present(errorAlert, animated: true)
                }
            }
        }
    }

    // MARK: - Onboarding State

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
            // User exists in Firebase but not in Core Data (e.g. app reinstall). Bootstrap them!
            let newUser = CDUser(context: context)
            newUser.id = UUID()
            newUser.firebaseUID = uid
            newUser.createdAt = Date()
            newUser.name = ""
            newUser.activityLevel = ""
            newUser.dietPattern = ""
            newUser.email = Auth.auth().currentUser?.email
            newUser.onboardingStep = 0
            appDelegate.saveContext()
            return false
        }
    }

    // MARK: - Private Factories

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
