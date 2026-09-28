import UIKit

enum WalkthroughStep: Int {
    case logPeriod   = 0   
    case logSymptom  = 1   
    case logMeal     = 2   
    case dietType    = 3   
    case workoutIntro = 4      
    case workoutAddExercise = 5 
    case workoutEditName = 6   
    case workoutActivityLevel = 7 
    case workoutPremade = 8    
    case chatbotPrompt = 9     
    case completed   = 10      
}

protocol WalkthroughManagerDelegate: AnyObject {

    func walkthroughDidReachStep(_ step: WalkthroughStep)

    func walkthroughDidComplete()
}

final class WalkthroughManager {

    static let shared = WalkthroughManager()
    private init() {}

    private(set) var currentStep: WalkthroughStep = .logPeriod
    private(set) var isActive: Bool = false
    private(set) var isAbortedMode: Bool = false

    private var delegates: [WeakDelegate] = []

    var shouldStartWalkthrough: Bool {
        let onboarded = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        let walkthroughDone = UserDefaults.standard.bool(forKey: "hasCompletedWalkthrough")
        return onboarded && !walkthroughDone
    }

    func startWalkthrough() {
        guard !isActive else { return }
        isActive = true
        currentStep = .logPeriod
        notifyDelegates(step: currentStep)
    }

    func addDelegate(_ delegate: WalkthroughManagerDelegate) {

        delegates.removeAll { $0.value == nil }

        if !delegates.contains(where: { $0.value === delegate }) {
            delegates.append(WeakDelegate(delegate))
        }
    }

    func removeDelegate(_ delegate: WalkthroughManagerDelegate) {
        delegates.removeAll { $0.value === delegate || $0.value == nil }
    }

    func advanceToStep(_ step: WalkthroughStep) {
        guard isActive else { return }
        currentStep = step
        if step == .completed {
            completeWalkthrough()
        } else {
            notifyDelegates(step: step)
        }
    }

    func advanceToNextStep() {
        guard isActive, let next = WalkthroughStep(rawValue: currentStep.rawValue + 1) else { return }
        advanceToStep(next)
    }

    func completeWalkthrough() {
        isActive = false
        isAbortedMode = false
        currentStep = .completed
        UserDefaults.standard.set(true, forKey: "hasCompletedWalkthrough")
        delegates.forEach { $0.value?.walkthroughDidComplete() }
        delegates.removeAll()
    }

    func handleWalkthroughAborted() {
        guard isActive else { return }
        isAbortedMode = true
        continueAbortedFlow()
    }

    func continueAbortedFlow() {
        completeWalkthrough()
        showAllSetCongrats()
    }



    private func showAllSetCongrats() {
        guard let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow }) else { return }

        WalkthroughCongratsView.present(
            in: window,
            title: "You're All Set!",
            body: "Your profile is fully configured. Enjoy using PCOS App!",
            continueTitle: "Get Started"
        ) {}
    }

    private func notifyDelegates(step: WalkthroughStep) {
        delegates.removeAll { $0.value == nil }
        delegates.forEach { $0.value?.walkthroughDidReachStep(step) }
    }

    private class WeakDelegate {
        weak var value: WalkthroughManagerDelegate?
        init(_ v: WalkthroughManagerDelegate) { self.value = v }
    }
}
