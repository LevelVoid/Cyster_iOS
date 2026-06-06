import UIKit

class WorkoutPieChart: UIView {

    struct WorkoutData {
        let name: String
        let value: Int
        let color: UIColor
    }

    private var segments: [WorkoutData] = []
    private var total: Int = 0
    private let donutWidth: CGFloat = 30 

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = .clear
    }

    func configure(with workoutData: [WorkoutData]) {
        self.segments = workoutData
        self.total = workoutData.reduce(0) { $0 + $1.value }
        setNeedsDisplay() 
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)

        guard total > 0, !segments.isEmpty else { return }

        let center = CGPoint(x: rect.width / 2, y: rect.height / 2)
        let radius = min(rect.width, rect.height) / 2 - 10 

        var startAngle: CGFloat = -.pi / 2 

        for segment in segments {
            let percentage = CGFloat(segment.value) / CGFloat(total)
            let endAngle = startAngle + (2 * .pi * percentage)

            let path = UIBezierPath()
            path.move(to: center)
            path.addArc(withCenter: center,
                        radius: radius,
                        startAngle: startAngle,
                        endAngle: endAngle,
                        clockwise: true)
            path.close()

            segment.color.setFill()
            path.fill()

            startAngle = endAngle
        }

        let innerCircle = UIBezierPath(arcCenter: center,
                                       radius: radius - donutWidth,
                                       startAngle: 0,
                                       endAngle: 2 * .pi,
                                       clockwise: true)

        (superview?.backgroundColor ?? UIColor.systemBackground).setFill()
        innerCircle.fill()
    }

    func setDonutWidth(_ width: CGFloat) {

        setNeedsDisplay()
    }
}

class WorkoutPieChartView: UIView {

    private let pieChart = WorkoutPieChart()
    private let legendStackView = UIStackView()

    private let totalLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        backgroundColor = .systemBackground
        layer.cornerRadius = 16

        totalLabel.font = .systemFont(ofSize: 24, weight: .bold)
        totalLabel.textColor = .label
        totalLabel.textAlignment = .center
        totalLabel.translatesAutoresizingMaskIntoConstraints = false

        pieChart.translatesAutoresizingMaskIntoConstraints = false

        legendStackView.axis = .vertical
        legendStackView.spacing = 12
        legendStackView.alignment = .leading
        legendStackView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(pieChart)
        addSubview(totalLabel)
        addSubview(legendStackView)

        setupConstraints()
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([

            pieChart.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            pieChart.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            pieChart.widthAnchor.constraint(equalToConstant: 150),
            pieChart.heightAnchor.constraint(equalToConstant: 150),

            totalLabel.centerXAnchor.constraint(equalTo: pieChart.centerXAnchor),
            totalLabel.centerYAnchor.constraint(equalTo: pieChart.centerYAnchor),

            legendStackView.leadingAnchor.constraint(equalTo: pieChart.trailingAnchor, constant: 24),
            legendStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            legendStackView.centerYAnchor.constraint(equalTo: pieChart.centerYAnchor),

            pieChart.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -16)
        ])
    }

    func configure(with workoutData: [WorkoutPieChart.WorkoutData]) {

        pieChart.configure(with: workoutData)

        let total = workoutData.reduce(0) { $0 + $1.value }
        totalLabel.text = "\(total)"

        legendStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        for data in workoutData {
            let legendItem = createLegendItem(color: data.color, name: data.name, value: data.value)
            legendStackView.addArrangedSubview(legendItem)
        }
    }

    private func createLegendItem(color: UIColor, name: String, value: Int) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let colorBox = UIView()
        colorBox.backgroundColor = color
        colorBox.layer.cornerRadius = 6
        colorBox.translatesAutoresizingMaskIntoConstraints = false

        let nameLabel = UILabel()
        nameLabel.text = name
        nameLabel.font = .systemFont(ofSize: 15, weight: .medium)
        nameLabel.textColor = .label
        nameLabel.translatesAutoresizingMaskIntoConstraints = false

        let valueLabel = UILabel()
        valueLabel.text = "\(value)"
        valueLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        valueLabel.textColor = .secondaryLabel
        valueLabel.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(colorBox)
        container.addSubview(nameLabel)
        container.addSubview(valueLabel)

        NSLayoutConstraint.activate([

            colorBox.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            colorBox.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            colorBox.widthAnchor.constraint(equalToConstant: 12),
            colorBox.heightAnchor.constraint(equalToConstant: 12),

            nameLabel.leadingAnchor.constraint(equalTo: colorBox.trailingAnchor, constant: 8),
            nameLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),

            valueLabel.leadingAnchor.constraint(equalTo: nameLabel.trailingAnchor, constant: 8),
            valueLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            valueLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),

            container.heightAnchor.constraint(equalToConstant: 24)
        ])

        return container
    }
}

