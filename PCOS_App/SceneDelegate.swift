import UIKit

class MainTabBarController: UITabBarController {
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        forceBottomTabBar()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        forceBottomTabBar()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        forceBottomTabBar()
    }
    
    private func forceBottomTabBar() {
        if #available(iOS 18.0, *) {
            self.mode = .tabBar
            self.traitOverrides.horizontalSizeClass = .compact
        }
    }
}

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        let window = UIWindow(windowScene: windowScene)
        let storyboard = UIStoryboard(name: "Main", bundle: nil)

        if OnboardingManager.shared.hasSeenOnboarding || UserDefaults.standard.bool(forKey: "hasCompletedOnboarding") {
            let tabBarVC = storyboard.instantiateViewController(withIdentifier: "MainTabBarController") as! UITabBarController
            if #available(iOS 18.0, *) {
                tabBarVC.mode = .tabBar
            }
            window.rootViewController = tabBarVC
        } else {

            let onboardingStoryboard = UIStoryboard(name: "Onboarding", bundle: nil)
            if let onboardingVC = onboardingStoryboard.instantiateInitialViewController() {
                window.rootViewController = onboardingVC
            } else {
                let tabBarVC = storyboard.instantiateViewController(withIdentifier: "MainTabBarController") as! UITabBarController
                if #available(iOS 18.0, *) {
                    tabBarVC.mode = .tabBar
                }
                window.rootViewController = tabBarVC
            }
        }

        self.window = window
        window.makeKeyAndVisible()
    }

    func sceneDidDisconnect(_ scene: UIScene) {

    }

    func sceneDidBecomeActive(_ scene: UIScene) {

    }

    func sceneWillResignActive(_ scene: UIScene) {

    }

    func sceneWillEnterForeground(_ scene: UIScene) {

    }

    func sceneDidEnterBackground(_ scene: UIScene) {

    }

}

