import UIKit
import TipKit

/// Manages a sequential guided tour using native TipKit popovers.
@available(iOS 17.0, *)
final class GuidedTourManager {

    static let tourCompletedKey = "hasCompletedHomeGuidedTour"
    private let pink = UIColor(red: 0.88, green: 0.35, blue: 0.47, alpha: 1.0)

    var hasCompletedTour: Bool {
        get { UserDefaults.standard.bool(forKey: Self.tourCompletedKey) }
        set { UserDefaults.standard.set(newValue, forKey: Self.tourCompletedKey) }
    }

    private weak var presenter: UIViewController?
    private var queue: [() -> Void] = []
    private var observationTask: Task<Void, Never>?

    /// Build the tour queue, then call `start()`.
    func setup(presenter: UIViewController) {
        self.presenter = presenter
        queue.removeAll()
    }

    /// Enqueue a tip anchored to a UIView.
    func enqueue<T: Tip>(_ tip: T, sourceView: UIView) {
        queue.append { [weak self] in
            self?.show(tip, sourceItem: sourceView)
        }
    }

    /// Enqueue a tip anchored to a UIBarButtonItem.
    func enqueue<T: Tip>(_ tip: T, barButtonItem: UIBarButtonItem) {
        queue.append { [weak self] in
            self?.show(tip, sourceItem: barButtonItem)
        }
    }

    func start() {
        // Reset tip datastore so previously-dismissed tips are fresh again.
        // This only runs on first launch (guarded by hasCompletedTour).
        try? Tips.resetDatastore()
        try? Tips.configure([
            .datastoreLocation(.applicationDefault),
            .displayFrequency(.immediate)
        ])
        // Give TipKit a moment to settle after the reset before showing tips
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.advance()
        }
    }

    func cancel() {
        observationTask?.cancel()
        queue.removeAll()
        if let p = presenter, p.presentedViewController is TipUIPopoverViewController {
            p.dismiss(animated: false)
        }
    }

    // MARK: - Private

    private func show<T: Tip>(_ tip: T, sourceItem: some UIPopoverPresentationControllerSourceItem) {
        guard let presenter = presenter, presenter.view.window != nil else {
            advance(); return
        }

        // Wait for any previous popover to fully dismiss before presenting
        if presenter.presentedViewController != nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
                self?.show(tip, sourceItem: sourceItem)
            }
            return
        }

        if let view = sourceItem as? UIView, view.window == nil {
            advance(); return
        }

        let popoverVC = TipUIPopoverViewController(tip, sourceItem: sourceItem)
        popoverVC.view.tintColor = pink
        presenter.present(popoverVC, animated: true)

        // Wait for the user to explicitly dismiss the tip (X button or tap outside).
        // shouldDisplayUpdates emits `false` only when the user interacts.
        observationTask = Task { @MainActor [weak self, weak presenter] in
            for await shouldDisplay in tip.shouldDisplayUpdates {
                if !shouldDisplay {
                    // User dismissed — close the popover if it's still up
                    if let presenter,
                       presenter.presentedViewController is TipUIPopoverViewController {
                        presenter.dismiss(animated: true)
                    }
                    // Wait for dismiss animation to finish
                    try? await Task.sleep(for: .milliseconds(500))
                    self?.advance()
                    break
                }
            }
        }
    }

    private func advance() {
        guard !queue.isEmpty else {
            hasCompletedTour = true
            return
        }
        let next = queue.removeFirst()
        next()
    }
}
