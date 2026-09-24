import UIKit
import FirebaseAuth

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
        return UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
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

        if resuming {
            // Attempt to resume at the right step via storyboard identifiers.
            // For now, if onboarding is incomplete but auth exists, start from Name.
            if let vc = storyboard.instantiateViewController(withIdentifier: "NameViewController") as? UIViewController {
                let nav = UINavigationController(rootViewController: vc)
                nav.setNavigationBarHidden(false, animated: false)
                return nav
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
