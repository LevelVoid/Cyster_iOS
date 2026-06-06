import UIKit

final class PhaseStoryPageViewController: UIPageViewController {

    var phaseSignal: PhaseSignal!
    var startIndex: Int = 0

    private var pages: [UIViewController] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        edgesForExtendedLayout = []

        configureNavBar()
        configurePages()
        disableSwipe()

    }

    private func configureNavBar() {

        title = phaseSignal.understanding.heading

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(closeTapped)
        )

        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always

        let appearance = UINavigationBarAppearance()
        appearance.backgroundColor = UIColor(hex: "#FCEEED")
        appearance.shadowColor = .clear

        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
    }

    private func configurePages() {

        let storyboard = UIStoryboard(name: "Home", bundle: nil)

        let phase01VC = storyboard.instantiateViewController(
            withIdentifier: "Phase01ViewController"
        ) as! Phase01ViewController

        let phase02VC = storyboard.instantiateViewController(
            withIdentifier: "Phase02ViewController"
        ) as! Phase02ViewController

        let phase03VC = storyboard.instantiateViewController(
            withIdentifier: "Phase03ViewController"
        ) as! Phase03ViewController

        phase01VC.phaseSignal = phaseSignal
        phase02VC.phaseSignal = phaseSignal
        phase03VC.phaseSignal = phaseSignal

        pages = [phase01VC, phase02VC, phase03VC]

        setViewControllers(
            [pages[startIndex]],
            direction: .forward,
            animated: false
        )

    }

    private func disableSwipe() {
        view.gestureRecognizers?
            .filter { $0 is UIPanGestureRecognizer }
            .forEach { $0.isEnabled = false }
    }

    @objc private func closeTapped() {
        dismiss(animated: true)
    }
}
