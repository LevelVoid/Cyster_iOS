import UIKit

class MovementTypeViewController: UIViewController {

    @IBOutlet weak var sedentaryView: UIView!
    @IBOutlet weak var lightMovementsView: UIView!
    @IBOutlet weak var regularMovementsView: UIView!
    @IBOutlet weak var veryActiveView: UIView!

    @IBOutlet weak var nextButton: UIButton!
    private var selectedView: UIView?
    private var selectedMovementType: String?

    private var originalBackgroundColors: [Int: UIColor] = [:]

    override func viewDidLoad() {
        super.viewDidLoad()

        nextButton.tintColor = UIColor(hex:"FE7A96")
        sedentaryView.layer.cornerRadius = 20
        lightMovementsView.layer.cornerRadius = 20
        regularMovementsView.layer.cornerRadius = 20
        veryActiveView.layer.cornerRadius = 20

        nextButton.alpha = 0.5

        addTapGesture(to: sedentaryView, movementType: "Sedentary Type")
        addTapGesture(to: lightMovementsView, movementType: "Light Movements")
        addTapGesture(to: regularMovementsView, movementType: "Regular Movements")
        addTapGesture(to: veryActiveView, movementType: "Very active on most days")

        let allViews = [sedentaryView, lightMovementsView, regularMovementsView, veryActiveView]
        for view in allViews {
            if let view = view {
                originalBackgroundColors[view.tag] = view.backgroundColor
            }
        }
    }

    private func addTapGesture(to view: UIView, movementType: String) {
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(viewTapped(_:)))
            view.isUserInteractionEnabled = true
            view.tag = getTag(for: movementType)
            view.addGestureRecognizer(tapGesture)
        }
    private func getTag(for movementType: String) -> Int {
    switch movementType {
    case "Sedentary Type": return 1
    case "Light Movements": return 2
    case "Regular Movements": return 3
    case "Very active on most days": return 4
    default: return 0
    }
        }

    private func getMovementType(from tag: Int) -> String {
            switch tag {
            case 1: return "Sedentary Type"
            case 2: return "Light Movements"
            case 3: return "Regular Movements"
            case 4: return "Very active on most days"
            default: return ""
            }
        }
    @objc private func viewTapped(_ gesture: UITapGestureRecognizer) {
            guard let tappedView = gesture.view else { return }

            if let previousView = selectedView {
                previousView.layer.borderWidth = 0
                previousView.backgroundColor = originalBackgroundColors[previousView.tag] ?? UIColor(red: 0.95, green: 0.85, blue: 0.90, alpha: 1.0)
            }

            selectedView = tappedView
            selectedMovementType = getMovementType(from: tappedView.tag)

            tappedView.layer.borderWidth = 3
        tappedView.layer.borderColor = UIColor(hex:"#fe7a96").cgColor
        tappedView.backgroundColor = UIColor(hex:"#fe7a96").withAlphaComponent(0.1)

            nextButton.alpha = 1.0
        }

    @IBAction func nextButtonTapped(_ sender: UIButton) {
        if WalkthroughManager.shared.isActive {
            guard let movementType = selectedMovementType else { return }

            saveMovementType(movementType)

            dismiss(animated: true) {
                if WalkthroughManager.shared.isAbortedMode {
                    WalkthroughManager.shared.continueAbortedFlow()
                } else {
                    WalkthroughManager.shared.advanceToStep(.workoutPremade)
                }
            }
        }
    }

    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if WalkthroughManager.shared.isActive {
            return false 
        }
        guard let movementType = selectedMovementType else { return false }
        saveMovementType(movementType)
        print("Saved movement type: \(movementType)")
        return true
    }

    private func saveMovementType(_ movementType: String) {
        UserDefaults.standard.set(movementType, forKey: "userWorkoutType")

        ProfileService.shared.updateActivityLevel(movementType)
    }

}
