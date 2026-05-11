
//
//  WalkthroughManager.swift
//  PCOS_App
//

import UIKit

// MARK: - Walkthrough Step

enum WalkthroughStep: Int {
    case logPeriod   = 0   // Step 1 – Home: tap log period button
    case logSymptom  = 1   // Step 2 – Home: tap add-symptom cell
    case logMeal     = 2   // Step 3 – Diet: tap add meal button
    case dietType    = 3   // Step 3b – Diet type selection
    case workoutIntro = 4      // Step 4 – Workout tab intro (points to + routine)
    case workoutAddExercise = 5 // Step 5 – Inside CreateRoutineVC, points to add exercise
    case workoutEditName = 6   // Step 6 – Inside CreateRoutineVC, points to name field / save
    case workoutActivityLevel = 7 // Step 7 - After save, prompt to set MovementType
    case workoutPremade = 8    // Step 8 - Back in workout tab, points to recommended routine
    case chatbotPrompt = 9     // Step 9 - Home tab, points to chatbot
    case completed   = 10      // All done
}

// MARK: - Delegate

protocol WalkthroughManagerDelegate: AnyObject {
    /// Called when the manager wants this screen to show its step UI
    func walkthroughDidReachStep(_ step: WalkthroughStep)
    /// Called when walkthrough finishes entirely
    func walkthroughDidComplete()
}

// MARK: - Manager

final class WalkthroughManager {

    static let shared = WalkthroughManager()
    private init() {}

    // MARK: State

    private(set) var currentStep: WalkthroughStep = .logPeriod
    private(set) var isActive: Bool = false

    /// Weak delegates – Home and Diet both register themselves
    private var delegates: [WeakDelegate] = []

    // MARK: Public API

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
        // Remove stale entries first
        delegates.removeAll { $0.value == nil }
        // Don't add duplicates
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
        currentStep = .completed
        UserDefaults.standard.set(true, forKey: "hasCompletedWalkthrough")
        delegates.forEach { $0.value?.walkthroughDidComplete() }
        delegates.removeAll()
    }

    // MARK: Private

    private func notifyDelegates(step: WalkthroughStep) {
        delegates.removeAll { $0.value == nil }
        delegates.forEach { $0.value?.walkthroughDidReachStep(step) }
    }

    // MARK: Weak wrapper

    private class WeakDelegate {
        weak var value: WalkthroughManagerDelegate?
        init(_ v: WalkthroughManagerDelegate) { self.value = v }
    }
}
