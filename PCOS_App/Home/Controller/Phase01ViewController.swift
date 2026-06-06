import UIKit

class Phase01ViewController: UIViewController {
    @IBOutlet weak var CycleImage: UIImageView!
    @IBOutlet weak var card1View:UIView!
    @IBOutlet weak var CycleInformation: UILabel!
    @IBOutlet weak var heading: UILabel!
    var phaseSignal: PhaseSignal!

        override func viewDidLoad() {
            super.viewDidLoad()
            setupUI()
        }

        private func setupUI() {

            heading.text = phaseSignal.understanding.heading
            heading.isHidden = true

            CycleInformation.isHidden = true

            card1View.backgroundColor = .clear

            let stackView = UIStackView()
            stackView.axis = .vertical
            stackView.spacing = 16
            stackView.translatesAutoresizingMaskIntoConstraints = false

            let icons = getIcons(for: phaseSignal.phase)
            for (index, description) in phaseSignal.understanding.descriptions.enumerated() {

                let card = UIView()
                card.backgroundColor = .white
                card.layer.cornerRadius = 16
                card.translatesAutoresizingMaskIntoConstraints = false

                let iconName = icons[index % icons.count]
                let imageView = UIImageView(image: UIImage(systemName: iconName))
                imageView.translatesAutoresizingMaskIntoConstraints = false
                imageView.contentMode = .scaleAspectFit
                imageView.tintColor = .black
                card.addSubview(imageView)

                let label = UILabel()
                label.text = description
                label.font = CycleInformation.font
                label.textColor = CycleInformation.textColor
                label.numberOfLines = 0
                label.textAlignment = .natural
                label.translatesAutoresizingMaskIntoConstraints = false

                card.addSubview(label)

                NSLayoutConstraint.activate([
                    imageView.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
                    imageView.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
                    imageView.widthAnchor.constraint(equalToConstant: 30),
                    imageView.heightAnchor.constraint(equalToConstant: 30),

                    label.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
                    label.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 16),
                    label.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
                    label.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16)
                ])

                stackView.addArrangedSubview(card)
            }

            card1View.addSubview(stackView)

            NSLayoutConstraint.activate([
                stackView.topAnchor.constraint(equalTo: card1View.topAnchor, constant: 0),
                stackView.leadingAnchor.constraint(equalTo: card1View.leadingAnchor, constant: 0),
                stackView.trailingAnchor.constraint(equalTo: card1View.trailingAnchor, constant: 0),
                stackView.bottomAnchor.constraint(lessThanOrEqualTo: card1View.bottomAnchor, constant: 0)
            ])

            CycleImage.isHidden = true
        }

    private func getIcons(for phase: Any) -> [String] {
        let phaseStr = String(describing: phase).lowercased()
        if phaseStr.contains("follicular") {
            return ["calendar", "hand.raised.fill", "circle.grid.2x2"]
        } else if phaseStr.contains("ovulation") {
            return ["pause.circle", "sparkles", "chart.xyaxis.line"]
        } else if phaseStr.contains("luteal") {
            return ["leaf.fill", "xmark.circle", "bolt.heart"]
        } else if phaseStr.contains("menstrual") {
            return ["square.stack.3d.up", "drop.triangle.fill", "battery.25"]
        }
        return ["heart.text.clipboard", "heart.text.clipboard", "heart.text.clipboard", "heart.text.clipboard"]
    }

}
