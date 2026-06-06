import UIKit
import HealthKit

class SummaryViewController: UIViewController {

    var completedWorkout: CompletedWorkout!

    @IBOutlet weak var containerView: UIView!

    let caloriesGoal = 600.0
    let durationGoalSeconds = 120 * 60  

    @IBOutlet weak var caloriesValueLabel: UILabel!
    @IBOutlet weak var caloriesGoalLabel: UILabel!

    @IBOutlet weak var exercisesDoneLabel: UILabel!

    @IBOutlet weak var durationValueLabel: UILabel!
    @IBOutlet weak var durationGoalLabel: UILabel!

    @IBOutlet weak var caloriesTitleLabel: UILabel!
    @IBOutlet weak var exercisesTitleLabel: UILabel!
    @IBOutlet weak var durationTitleLabel: UILabel!

    @IBOutlet weak var caloriesCard: UIView!
    @IBOutlet weak var exercisesCard: UIView!
    @IBOutlet weak var durationCard: UIView!

    private var caloriesSourceLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor(hex: "#FCEEED")

        navigationItem.hidesBackButton = true

        addCaloriesSourceLabel()
        setupUI()
        applyCardStyling()
        showConfetti()

        fetchBestCalorieEstimate()
    }

    private func addCaloriesSourceLabel() {
        guard caloriesCard != nil else { return }
        let label = UILabel()
        label.isHidden = true   
        label.translatesAutoresizingMaskIntoConstraints = false
        caloriesCard.addSubview(label)
        caloriesSourceLabel = label
    }

    func setupUI() {
        containerView.layer.cornerRadius = 24

        let totalSeconds = completedWorkout.durationSeconds
        durationValueLabel.text = formatDuration(totalSeconds)

        caloriesValueLabel.text = "—"

        let completedExercises = completedWorkout.exercises.filter {
            $0.sets.allSatisfy { $0.completionState == .completed }
        }.count
        exercisesDoneLabel.text = "\(completedExercises)"
    }

    private var hkFetchRetries = 0

    private func fetchBestCalorieEstimate() {

        let delay: TimeInterval = hkFetchRetries == 0 ? 5 : 0
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            self?.runCalorieQuery()
        }
    }

    private func runCalorieQuery() {
        let start = completedWorkout.startTime
        let end = start.addingTimeInterval(TimeInterval(completedWorkout.durationSeconds))

        HealthKitManager.shared.fetchActiveCalories(from: start, to: end) { [weak self] sessionCals in
            guard let self = self else { return }

            if sessionCals > 0 {
                print("[Calories] Source: via Apple Watch (direct HK calories) | Value: \(sessionCals) kcal")
                DispatchQueue.main.async {
                    self.caloriesValueLabel.text = String(format: "%.0f", sessionCals)
                    self.saveAndSyncCalories(sessionCals)
                }
            } else {
                print("[Calories] No direct HK calorie data found — trying heart rate...")
                self.fetchHeartRateBasedCalories()
            }
        }
    }

    private func fetchHeartRateBasedCalories() {
        let start = completedWorkout.startTime
        let end = start.addingTimeInterval(TimeInterval(completedWorkout.durationSeconds))

        HealthKitManager.shared.fetchHeartRate(from: start, to: end) { [weak self] avgHR in
            guard let self = self else { return }

            if let avgHR = avgHR, avgHR > 0 {
                let durationMin = Double(self.completedWorkout.durationSeconds) / 60.0
                let hkm = HealthKitManager.shared
                let calories = hkm.estimateCaloriesFromHeartRate(
                    avgHR: avgHR,
                    ageYears: hkm.userAge,
                    weightKg: hkm.userWeightKg,
                    durationMin: durationMin,
                    isFemale: true
                )
                print("[Calories] Source: Keytel formula | Avg HR: \(Int(avgHR)) bpm | Duration: \(String(format: "%.1f", durationMin)) min | Age: \(hkm.userAge) | Weight: \(hkm.userWeightKg) kg | Result: \(String(format: "%.1f", calories)) kcal")
                DispatchQueue.main.async {
                    self.caloriesValueLabel.text = String(format: "%.0f", calories)
                    self.saveAndSyncCalories(calories)
                }
            } else {

                if self.hkFetchRetries < 2 {
                    self.hkFetchRetries += 1
                    print("[Calories] No HR data yet — retry \(self.hkFetchRetries)/2 in 15s...")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 15) { [weak self] in
                        self?.runCalorieQuery()
                    }
                } else {
                    print("[Calories] All retries exhausted — no Apple Watch or no HR recorded")
                    DispatchQueue.main.async {
                        self.caloriesValueLabel.text = "—"
                        self.saveAndSyncCalories(0)
                    }
                }
            }
        }
    }

    private func saveAndSyncCalories(_ calories: Double) {

        completedWorkout.caloriesBurned = calories

        CompletedWorkoutsDataStore.shared.save(completedWorkout)

        DailyActivityDataStore.shared.syncAllWorkouts(for: completedWorkout.date)
    }

    func applyCardStyling() {
        let cards = [durationCard, caloriesCard, exercisesCard]
        cards.forEach { card in
            card?.layer.cornerRadius = 20
            card?.backgroundColor = .systemBackground
            card?.layer.masksToBounds = false

            card?.layer.shadowColor = UIColor.black.cgColor
            card?.layer.shadowOffset = CGSize(width: 0, height: 4)
            card?.layer.shadowRadius = 8
            card?.layer.shadowOpacity = 0.05
        }

        setupStackViews()
    }

    private func setupStackViews() {

        if let card = caloriesCard, let val = caloriesValueLabel, let unit = caloriesGoalLabel, let title = caloriesTitleLabel {
            configureCardStack(card: card, valueLabel: val, unitLabel: unit, titleLabel: title)
        }

        if let card = exercisesCard, let val = exercisesDoneLabel, let title = exercisesTitleLabel {
            configureCardStack(card: card, valueLabel: val, unitLabel: nil, titleLabel: title)
        }

        if let card = durationCard, let val = durationValueLabel, let unit = durationGoalLabel, let title = durationTitleLabel {
            configureCardStack(card: card, valueLabel: val, unitLabel: unit, titleLabel: title)
        }
    }

    private func configureCardStack(card: UIView, valueLabel: UILabel, unitLabel: UILabel?, titleLabel: UILabel) {

        card.subviews.forEach { $0.removeFromSuperview() }

        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let valueStack = UIStackView()
        valueStack.axis = .horizontal
        valueStack.alignment = .firstBaseline
        valueStack.spacing = 4
        valueStack.translatesAutoresizingMaskIntoConstraints = false
        valueStack.addArrangedSubview(valueLabel)

        if let unit = unitLabel {
            unit.translatesAutoresizingMaskIntoConstraints = false
            valueStack.addArrangedSubview(unit)
        }

        let mainStack = UIStackView()
        mainStack.axis = .vertical
        mainStack.alignment = .center
        mainStack.spacing = 8
        mainStack.translatesAutoresizingMaskIntoConstraints = false

        mainStack.addArrangedSubview(valueStack)
        mainStack.addArrangedSubview(titleLabel)

        card.addSubview(mainStack)

        NSLayoutConstraint.activate([
            mainStack.centerXAnchor.constraint(equalTo: card.centerXAnchor),
            mainStack.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            mainStack.leadingAnchor.constraint(greaterThanOrEqualTo: card.leadingAnchor, constant: 8),
            mainStack.trailingAnchor.constraint(lessThanOrEqualTo: card.trailingAnchor, constant: -8)
        ])

        titleLabel.textColor = .secondaryLabel
        titleLabel.font = .preferredFont(forTextStyle: .footnote)
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 2
    }

    func formatDuration(_ seconds: Int) -> String {
        let hrs = seconds / 3600
        let mins = (seconds % 3600) / 60

        if hrs > 0 {
            return "\(hrs)h \(mins)"
        } else {
            return "\(mins)"
        }
    }

    func showConfetti() {
        let confettiLayer = CAEmitterLayer()

        confettiLayer.emitterPosition = CGPoint(x: view.bounds.width / 2, y: -50)
        confettiLayer.emitterShape = .line
        confettiLayer.emitterSize = CGSize(width: view.bounds.size.width, height: 1)

        let colors: [UIColor] = [
            UIColor(red: 1.0, green: 0.8, blue: 0.0, alpha: 1.0),    
            UIColor(red: 1.0, green: 0.4, blue: 0.6, alpha: 1.0),    
            UIColor(red: 0.5, green: 0.2, blue: 0.9, alpha: 1.0),    
            UIColor(red: 0.2, green: 0.9, blue: 0.5, alpha: 1.0),    
            UIColor(red: 1.0, green: 0.5, blue: 0.0, alpha: 1.0),    
            UIColor(red: 0.2, green: 0.6, blue: 1.0, alpha: 1.0),    
            UIColor(red: 1.0, green: 0.2, blue: 0.3, alpha: 1.0),    
            UIColor(red: 0.9, green: 0.9, blue: 0.2, alpha: 1.0)     
        ]

        var cells: [CAEmitterCell] = []

        for color in colors {
            for _ in 0..<1 {                              
                let cell = CAEmitterCell()

                cell.birthRate = 3                         
                cell.lifetime = 6.0                        
                cell.lifetimeRange = 2                     

                cell.velocity = CGFloat.random(in: 150...250)   
                cell.velocityRange = 60                    
                cell.emissionLongitude = .pi
                cell.emissionRange = .pi / 4              

                cell.spin = CGFloat.random(in: 1...3)     
                cell.spinRange = 2                         

                cell.scale = CGFloat.random(in: 0.2...0.4)  
                cell.scaleRange = 0.1                      
                cell.scaleSpeed = -0.05

                cell.yAcceleration = 150
                cell.xAcceleration = CGFloat.random(in: -20...20)

                cell.alphaSpeed = -0.15                    
                cell.color = color.cgColor

                let shapes = ["circle", "square", "triangle"]
                let randomShape = shapes.randomElement() ?? "circle"
                cell.contents = confettiImage(shape: randomShape, color: color)?.cgImage

                cells.append(cell)
            }
        }
        confettiLayer.emitterCells = cells
        view.layer.addSublayer(confettiLayer)

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            confettiLayer.birthRate = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 12) {
            confettiLayer.removeFromSuperlayer()
        }
    }
    func confettiImage(shape: String, color: UIColor) -> UIImage? {
        let size = CGSize(width: 10, height: 10)
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { context in
            color.setFill()

            switch shape {
            case "square":
                let rect = CGRect(x: 1, y: 1, width: 8, height: 8)
                context.cgContext.fill(rect)

            case "triangle":
                let path = UIBezierPath()
                path.move(to: CGPoint(x: size.width/2, y: 1))
                path.addLine(to: CGPoint(x: 1, y: size.height - 1))
                path.addLine(to: CGPoint(x: size.width - 1, y: size.height - 1))
                path.close()
                path.fill()

            case "circle":
                let rect = CGRect(x: 1, y: 1, width: 8, height: 8)
                context.cgContext.fillEllipse(in: rect)

            default:
                break
            }
        }
    }
        @IBAction func doneButtonTapped(_ sender: UIButton) {

            view.window?.rootViewController?.dismiss(animated: true)

        }

    }
