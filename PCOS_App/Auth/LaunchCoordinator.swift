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
            navigateToNameViewController(from: viewController)
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
