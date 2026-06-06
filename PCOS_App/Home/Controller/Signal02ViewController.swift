import UIKit

final class Signal02ViewController: UIViewController {

    var signal: PCOSSignal!

    @IBOutlet weak var headingLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var doctorDisclaimerLabel: UILabel!
    @IBOutlet weak var card1View: UIView!
    @IBOutlet weak var card2View: UIView!

    private let cardColors: [UIColor] = [
        UIColor(hex: "#fce4e8")
    ]

    private var maxCardHeight: CGFloat = 0

    override func viewDidLoad() {
        super.viewDidLoad()

        card1View.layer.cornerRadius = 16
        card2View.layer.cornerRadius = 16

        setupTableView()
        bindData()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        tableView.layoutIfNeeded()
        let contentHeight = tableView.contentSize.height

        if let heightConstraint = tableView.constraints.first(where: { $0.firstAttribute == .height }) {
            tableView.removeConstraint(heightConstraint)
        }

        let heightConstraint = tableView.heightAnchor.constraint(equalToConstant: contentHeight)
        heightConstraint.priority = .defaultHigh
        heightConstraint.isActive = true
    }

    private func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.isScrollEnabled = false
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "AppearanceCell")

        tableView.constraints.filter { $0.firstAttribute == .height }.forEach {
            tableView.removeConstraint($0)
        }
    }

    private func bindData() {
        headingLabel.text = signal.appearanceHeading
        doctorDisclaimerLabel.text = signal.doctorDisclaimer

        calculateMaxCardHeight()

        tableView.reloadData()
    }

    private func calculateMaxCardHeight() {

        let cardWidth = tableView.bounds.width  
        let labelWidth = cardWidth - 40  

        var heights: [CGFloat] = []

        for description in signal.appearanceDescriptions {
            let label = UILabel()
            label.text = description
            label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
            label.numberOfLines = 0

            let size = label.sizeThatFits(CGSize(width: labelWidth, height: .greatestFiniteMagnitude))
            let cardHeight = size.height + 32 + 12  
            heights.append(cardHeight)
        }

        maxCardHeight = heights.max() ?? 80
    }
}

extension Signal02ViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return signal.appearanceDescriptions.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AppearanceCell", for: indexPath)

        cell.contentView.subviews.forEach { $0.removeFromSuperview() }

        let cardView = UIView()
        cardView.translatesAutoresizingMaskIntoConstraints = false
        cardView.backgroundColor = cardColors[indexPath.row % cardColors.count]

        cardView.layer.cornerRadius = (maxCardHeight - 12) / 2  
        cardView.layer.masksToBounds = true
        cell.contentView.addSubview(cardView)

        let descriptionLabel = UILabel()
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.text = signal.appearanceDescriptions[indexPath.row]
        descriptionLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        descriptionLabel.textColor = .black
        descriptionLabel.numberOfLines = 0
        descriptionLabel.textAlignment = .center
        cardView.addSubview(descriptionLabel)

        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 6),
            cardView.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 0),
            cardView.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: 0),
            cardView.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -6),

            descriptionLabel.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            descriptionLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 20),
            descriptionLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -20),
            descriptionLabel.topAnchor.constraint(greaterThanOrEqualTo: cardView.topAnchor, constant: 16),
            descriptionLabel.bottomAnchor.constraint(lessThanOrEqualTo: cardView.bottomAnchor, constant: -16)
        ])

        cell.selectionStyle = .none
        cell.backgroundColor = .clear

        return cell
    }
}

extension Signal02ViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {

        return maxCardHeight > 0 ? maxCardHeight : 80
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
}
