import UIKit

protocol HomeHeaderCollectionViewCellDelegate: AnyObject {
    func homeHeaderCellDidTapLogPeriod(_ cell: HomeHeaderCollectionViewCell)
}

class HomeHeaderCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var expectedLabel: UILabel!
    @IBOutlet weak var headerCardView: UIView!
    @IBOutlet weak var cellView: UIView!
    @IBOutlet weak var cycleDayLabel: UILabel!
    @IBOutlet weak var phaseLabel: UILabel!
    @IBOutlet weak var quoteLabel: UILabel!
    @IBOutlet weak var predictionLabel: UILabel!
    @IBOutlet weak var logPeriodButton: UIButton!
    @IBOutlet weak var calendarIcon: UIImageView!
    @IBOutlet weak var separatorView: UIView!

    weak var delegate: HomeHeaderCollectionViewCellDelegate?

    private let gradientLayer = CAGradientLayer()

    override func awakeFromNib() {
        super.awakeFromNib()
        setup()
    }

    private func setup() {
        cellView.backgroundColor = .clear

        let bottomConstraint = cellView.bottomAnchor.constraint(equalTo: headerCardView.bottomAnchor, constant: 16)
        bottomConstraint.priority = UILayoutPriority(999)
        bottomConstraint.isActive = true

        headerCardView.backgroundColor = .clear
        headerCardView.layer.cornerRadius = 24
        headerCardView.clipsToBounds = true
        setupGradient()

        expectedLabel.textColor = UIColor(hex: "FFFFFF").withAlphaComponent(0.60)

        if var config = logPeriodButton.configuration {
            config.cornerStyle = .capsule
            logPeriodButton.configuration = config
        }
        logPeriodButton.tintColor = UIColor(hex: "#ffffff").withAlphaComponent(0.25)
        logPeriodButton.addTarget(self, action: #selector(logPeriodButtonTapped), for: .touchUpInside)
    }

    @objc private func logPeriodButtonTapped() {
        delegate?.homeHeaderCellDidTapLogPeriod(self)
    }

    private func setupGradient() {
        gradientLayer.colors = [
            UIColor(red: 0.949, green: 0.541, blue: 0.690, alpha: 1).cgColor, 
            UIColor(red: 0.910, green: 0.376, blue: 0.478, alpha: 1).cgColor  
        ]
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.0)
        gradientLayer.endPoint   = CGPoint(x: 0.5, y: 1.0)
        gradientLayer.cornerRadius = 24

        headerCardView.backgroundColor = .clear

        headerCardView.layer.insertSublayer(gradientLayer, at: 0)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        gradientLayer.frame = headerCardView.bounds
    }

    func configure(cycleDay: Int, phase: Phase, prediction: PeriodPrediction) {

        cycleDayLabel.text = cycleDay > 0 ? "Cycle Day \(cycleDay)" : "No Cycle Logged"

        if phase == .unknown {
            phaseLabel.isHidden = true
        } else {
            phaseLabel.isHidden = false
            phaseLabel.text = phase.displayName
        }

        quoteLabel.text = phase.quote

        configurePrediction(prediction, cycleDay: cycleDay)
    }

    private func configurePrediction(_ prediction: PeriodPrediction, cycleDay: Int) {

        separatorView.isHidden = false
        calendarIcon.isHidden = false
        expectedLabel.isHidden = false
        predictionLabel.isHidden = false

        switch prediction.confidence {
        case .none:
            if cycleDay > 0 {

                expectedLabel.text = "Period Prediction"
                predictionLabel.text = "More data needed"
                predictionLabel.font = .systemFont(ofSize: 17, weight: .semibold)
            } else {

                expectedLabel.text = "Get Started"
                predictionLabel.text = "Log your first period"
                predictionLabel.font = .systemFont(ofSize: 17, weight: .semibold)
            }

        case .low, .medium, .high:
            guard let days = prediction.daysUntil else {

                expectedLabel.text = "Period Prediction"
                predictionLabel.text = "Log more cycles"
                predictionLabel.font = .systemFont(ofSize: 17, weight: .semibold)
                return
            }

            if prediction.isLate {

                expectedLabel.text = "Cycle Update"
                predictionLabel.text = "Cycle may be irregular"
                predictionLabel.font = .systemFont(ofSize: 17, weight: .semibold)

            } else if days == 0 {

                expectedLabel.text = "Expected Period"
                predictionLabel.text = "Today"
                predictionLabel.font = .boldSystemFont(ofSize: 22)

            } else if days < 0 {

                let overdue = abs(days)
                expectedLabel.text = "Overdue"
                predictionLabel.text = "Period \(overdue) day\(overdue == 1 ? "" : "s") late"
                predictionLabel.font = .systemFont(ofSize: 17, weight: .semibold)

            } else {

                expectedLabel.text = "Expected Period"
                if let date = prediction.predictedStartDate {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "MMM d"
                    predictionLabel.text = formatter.string(from: date)
                } else {
                    predictionLabel.text = "\(days) day\(days == 1 ? "" : "s")"
                }
                predictionLabel.font = .boldSystemFont(ofSize: 22)
            }
        }
    }
}
