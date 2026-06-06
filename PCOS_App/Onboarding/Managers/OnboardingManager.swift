import Foundation

final class OnboardingManager {
    static let shared = OnboardingManager()
    private let hasSeenOnboardingKey = "hasSeenFirstLaunchOnboarding"

    var hasSeenOnboarding: Bool {
        get { UserDefaults.standard.bool(forKey: hasSeenOnboardingKey) }
        set { UserDefaults.standard.set(newValue, forKey: hasSeenOnboardingKey) }
    }
}
