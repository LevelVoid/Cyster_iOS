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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        HealthKitManager.shared.requestAuthorization { granted, error in
            if let error = error {
                print("HealthKit auth error: \(error.localizedDescription)")
            } else {
                print("HealthKit authorization granted: \(granted)")
            }
        }
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
        window.rootViewController = LaunchCoordinator.shared.resolveRootViewController()
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

