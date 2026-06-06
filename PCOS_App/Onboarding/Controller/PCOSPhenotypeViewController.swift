import UIKit

class PCOSPhenotypeViewController: UIViewController {

    @IBOutlet weak var typeACard: UIView!
    @IBOutlet weak var typeBCard: UIView!
    @IBOutlet weak var typeCCard: UIView!
    @IBOutlet weak var typeDCard: UIView!
    @IBOutlet weak var dontKnowCard: UIView!

    @IBOutlet weak var continueButton: UIButton!

    private var selectedView: UIView?
    private var selectedPhenotype: PCOSPhenotype?

    private var originalBackgroundColors: [Int: UIColor] = [:]

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        setupCardGestures()
    }

    private func setupUI() {
        continueButton.tintColor = UIColor(hex: "FE7A96")

        let allCards = [typeACard, typeBCard, typeCCard, typeDCard, dontKnowCard]
        for card in allCards {
            card?.layer.cornerRadius = 20
        }
    }

    private func setupCardGestures() {

        addTapGesture(to: typeACard, phenotype: .typeA)
        addTapGesture(to: typeBCard, phenotype: .typeB)
        addTapGesture(to: typeCCard, phenotype: .typeC)
        addTapGesture(to: typeDCard, phenotype: .typeD)
        addTapGesture(to: dontKnowCard, phenotype: .unknown)

        let allCards = [typeACard, typeBCard, typeCCard, typeDCard, dontKnowCard]
        for card in allCards {
            if let card = card {
                originalBackgroundColors[card.tag] = card.backgroundColor
            }
        }
    }

    private func addTapGesture(to view: UIView?, phenotype: PCOSPhenotype) {
        guard let view = view else { return }

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(cardTapped(_:)))
        view.isUserInteractionEnabled = true
        view.tag = getTag(for: phenotype)
        view.addGestureRecognizer(tapGesture)
    }

    private func getTag(for phenotype: PCOSPhenotype) -> Int {
        switch phenotype {
        case .typeA: return 1
        case .typeB: return 2
        case .typeC: return 3
        case .typeD: return 4
        case .unknown: return 5
        }
    }

    private func getPhenotype(from tag: Int) -> PCOSPhenotype {
        switch tag {
        case 1: return .typeA
        case 2: return .typeB
        case 3: return .typeC
        case 4: return .typeD
        case 5: return .unknown
        default: return .unknown
        }
    }

    @objc private func cardTapped(_ gesture: UITapGestureRecognizer) {
        guard let tappedView = gesture.view else { return }

        if let previousView = selectedView {
            previousView.layer.borderWidth = 0
            previousView.backgroundColor = originalBackgroundColors[previousView.tag] ?? UIColor(red: 0.95, green: 0.85, blue: 0.90, alpha: 1.0)
        }

        selectedView = tappedView
        selectedPhenotype = getPhenotype(from: tappedView.tag)

        tappedView.layer.borderWidth = 3
        tappedView.layer.borderColor = UIColor(hex: "#fe7a96").cgColor
        tappedView.backgroundColor = UIColor(hex: "fe7a96").withAlphaComponent(0.1)
    }

    @IBAction func continueButtonTapped(_ sender: UIButton) {
        let phenotypeRawValue = selectedPhenotype?.rawValue ?? PCOSPhenotype.unknown.rawValue
        saveProfileAndContinue(phenotypeRawValue: phenotypeRawValue)
    }

    private func saveProfileAndContinue(phenotypeRawValue: String) {

        UserDefaults.standard.set(phenotypeRawValue, forKey: "userPCOSPhenotype")

        let name = UserDefaults.standard.string(forKey: "userName") ?? ""
        let dob = UserDefaults.standard.object(forKey: "userDOB") as? Date ?? Date()
        let dietType = UserDefaults.standard.string(forKey: "userDietType") ?? "Not sure yet"
        let workoutType = UserDefaults.standard.string(forKey: "userWorkoutType") ?? "Mostly sedentary"
        let pcosPhenotype = UserDefaults.standard.string(forKey: "userPCOSPhenotype") ?? "I Don't Know"

        let rawHeight = UserDefaults.standard.integer(forKey: "userHeight")
        let heightIsMetric = UserDefaults.standard.bool(forKey: "heightIsMetric")
        let heightInCm: Double = heightIsMetric ? Double(rawHeight) : Double(rawHeight) * 2.54

        let rawWeight = UserDefaults.standard.integer(forKey: "userWeight")
        let weightIsMetric = UserDefaults.standard.bool(forKey: "weightIsMetric")
        let weightInKg: Double = weightIsMetric ? Double(rawWeight) : Double(rawWeight) / 2.205

        let profile = ProfileModel(
            name: name,
            dob: dob,
            height: Int(heightInCm),
            weight: Int(weightInKg),
            dietType: dietType,
            workoutType: workoutType,
            pcosPhenotype: pcosPhenotype
        )

        ProfileService.shared.setProfile(to: profile)

        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")

        UserDefaults.standard.set(false, forKey: "hasCompletedWalkthrough")

        print("Complete profile saved! Height: \(heightInCm)cm, Weight: \(weightInKg)kg, Phenotype: \(pcosPhenotype)")

        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let tabBarVC = mainStoryboard.instantiateViewController(withIdentifier: "MainTabBarController") as! UITabBarController

        if #available(iOS 18.0, *) {
            tabBarVC.mode = .tabBar
        }

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController = tabBarVC
            window.makeKeyAndVisible()

            UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: nil)
        }
    }
}

