import UIKit

class PeriodCycleChartView: UIView {

    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let legendStackView = UIStackView()
    private let yAxisContainer = UIView()

    private var cycleData: [CycleData] = []
    private let barWidth: CGFloat = 40
    private let barSpacing: CGFloat = 20
    private let chartHeight: CGFloat = 200
    private let yAxisWidth: CGFloat = 30

    private func yAxisTicks(for maxValue: Int) -> [Int] {
        var ticks: [Int] = []
        var v = 0
        while v <= maxValue {
            ticks.append(v)
            v += 7
        }
        return ticks
    }

    enum LineType {
        case periodLength
        case cycleLength

        var color: UIColor {
            switch self {
            case .periodLength: return UIColor(red: 254.0/255.0, green: 122.0/255.0, blue: 150.0/255.0, alpha: 1.0)
            case .cycleLength: return UIColor(red: 0.7, green: 0.7, blue: 1.0, alpha: 1.0)
            }
        }

        var name: String {
            switch self {
            case .periodLength: return "Period Length"
            case .cycleLength: return "Cycle Length"
            }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    private func setupView() {

        addSubview(yAxisContainer)
        addSubview(scrollView)
        addSubview(legendStackView)

        scrollView.addSubview(contentView)

        yAxisContainer.translatesAutoresizingMaskIntoConstraints = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        legendStackView.translatesAutoresizingMaskIntoConstraints = false

        legendStackView.axis = .horizontal
        legendStackView.spacing = 20

        legendStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for type in [PeriodCycleChartView.LineType.periodLength, .cycleLength] {
            let itemView = createLegendItem(color: type.color, name: type.name)
            legendStackView.addArrangedSubview(itemView)
        }

        scrollView.showsHorizontalScrollIndicator = false

        NSLayoutConstraint.activate([

            yAxisContainer.topAnchor.constraint(equalTo: topAnchor),
            yAxisContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            yAxisContainer.widthAnchor.constraint(equalToConstant: yAxisWidth),
            yAxisContainer.bottomAnchor.constraint(equalTo: legendStackView.topAnchor, constant: -12),

            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: yAxisContainer.trailingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: legendStackView.topAnchor, constant: -12),

            legendStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            legendStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
            legendStackView.heightAnchor.constraint(equalToConstant: 20),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.heightAnchor.constraint(equalTo: scrollView.heightAnchor)
        ])
    }

    func configure(with data: [CycleData]) {

        self.cycleData = data.reversed()

        contentView.subviews.forEach { $0.removeFromSuperview() }
        yAxisContainer.subviews.forEach { $0.removeFromSuperview() }

        contentView.constraints.filter { $0.firstAttribute == .width }.forEach { $0.isActive = false }

        layoutIfNeeded() 
        let barsWidth = CGFloat(cycleData.count) * (barWidth + barSpacing) + 40
        let totalWidth = max(barsWidth, scrollView.bounds.width) 
        contentView.widthAnchor.constraint(equalToConstant: totalWidth).isActive = true

        let cycleLengths = cycleData.map{ $0.cycleLength }
        let maxCycleLength = cycleLengths.max() ?? 30
        let maxValue = max(maxCycleLength + 5, 35) 

        let monthLabelSpace: CGFloat = 25

        let ticks = yAxisTicks(for: maxValue)
        addYAxisLabelsAndGridlines(ticks: ticks, maxValue: maxValue, monthLabelSpace: monthLabelSpace, totalContentWidth: totalWidth)

        for (index, cycle) in cycleData.enumerated() {
            let xPosition = 20 + CGFloat(index) * (barWidth + barSpacing)
            createBar(at: xPosition, cycleLength: cycle.cycleLength, periodLength: cycle.periodLength, month: cycle.month, maxCycle: maxValue)
        }

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let maxOffsetX = self.scrollView.contentSize.width - self.scrollView.bounds.width
            if maxOffsetX > 0 {
                self.scrollView.setContentOffset(CGPoint(x: maxOffsetX, y: 0), animated: false)
            }
        }
    }

    private func addYAxisLabelsAndGridlines(ticks: [Int], maxValue: Int, monthLabelSpace: CGFloat, totalContentWidth: CGFloat) {

        layoutIfNeeded()

        let availableHeight = scrollView.bounds.height
        guard availableHeight > 0 else {

            DispatchQueue.main.async { [weak self] in
                self?.addYAxisLabelsAndGridlines(ticks: ticks, maxValue: maxValue, monthLabelSpace: monthLabelSpace, totalContentWidth: totalContentWidth)
            }
            return
        }

        let chartAreaHeight = availableHeight - monthLabelSpace

        for value in ticks {
            guard value <= maxValue else { continue }

            let fraction = CGFloat(value) / CGFloat(maxValue)
            let yFromBottom = fraction * chartAreaHeight
            let yPosition = availableHeight - monthLabelSpace - yFromBottom

            let label = UILabel()
            label.text = "\(value)"
            label.font = .systemFont(ofSize: 10, weight: .regular)
            label.textColor = UIColor.secondaryLabel
            label.textAlignment = .right
            label.translatesAutoresizingMaskIntoConstraints = false
            yAxisContainer.addSubview(label)

            NSLayoutConstraint.activate([
                label.trailingAnchor.constraint(equalTo: yAxisContainer.trailingAnchor, constant: -4),
                label.centerYAnchor.constraint(equalTo: yAxisContainer.topAnchor, constant: yPosition),
                label.widthAnchor.constraint(lessThanOrEqualToConstant: yAxisWidth - 4)
            ])

            let line = UIView()
            line.backgroundColor = UIColor.systemGray5
            line.translatesAutoresizingMaskIntoConstraints = false
            contentView.insertSubview(line, at: 0) 

            NSLayoutConstraint.activate([
                line.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                line.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                line.heightAnchor.constraint(equalToConstant: 0.5),
                line.topAnchor.constraint(equalTo: contentView.topAnchor, constant: yPosition)
            ])
        }
    }

    private func createBar(at x: CGFloat, cycleLength: Int, periodLength: Int, month: String, maxCycle: Int) {
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(containerView)

        let cycleBarHeight = (CGFloat(cycleLength) / CGFloat(maxCycle)) * chartHeight
        let periodBarHeight = (CGFloat(periodLength) / CGFloat(maxCycle)) * chartHeight

        let periodBar = UIView()
        periodBar.backgroundColor = UIColor(red: 254.0/255.0, green: 122.0/255.0, blue: 150.0/255.0, alpha: 1.0)
        periodBar.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        periodBar.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(periodBar)

        let cycleBar = UIView()
        cycleBar.backgroundColor = UIColor(red: 0.7, green: 0.7, blue: 1.0, alpha: 1.0)
        cycleBar.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        cycleBar.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(cycleBar)

        let cycleLengthLabel = UILabel()
        cycleLengthLabel.text = "\(cycleLength)"
        cycleLengthLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        cycleLengthLabel.textColor = UIColor(red: 0.5, green: 0.5, blue: 0.8, alpha: 1.0)
        cycleLengthLabel.textAlignment = .center
        cycleLengthLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(cycleLengthLabel)

        let periodLengthLabel = UILabel()
        periodLengthLabel.text = "\(periodLength)"
        periodLengthLabel.font = .systemFont(ofSize: 14, weight: .bold)
        periodLengthLabel.textColor = .white
        periodLengthLabel.textAlignment = .center
        periodLengthLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(periodLengthLabel)

        let monthLabel = UILabel()
        monthLabel.text = month
        monthLabel.font = .systemFont(ofSize: 12)
        monthLabel.textColor = .gray
        monthLabel.textAlignment = .center
        monthLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(monthLabel)

        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: x),
            containerView.widthAnchor.constraint(equalToConstant: barWidth),
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            periodBar.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            periodBar.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            periodBar.bottomAnchor.constraint(equalTo: monthLabel.topAnchor, constant: -10),
            periodBar.heightAnchor.constraint(equalToConstant: periodBarHeight),

            cycleBar.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            cycleBar.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            cycleBar.bottomAnchor.constraint(equalTo: periodBar.topAnchor),
            cycleBar.heightAnchor.constraint(equalToConstant: cycleBarHeight - periodBarHeight),

            cycleLengthLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            cycleLengthLabel.bottomAnchor.constraint(equalTo: cycleBar.topAnchor, constant: -4),

            periodLengthLabel.centerXAnchor.constraint(equalTo: periodBar.centerXAnchor),
            periodLengthLabel.centerYAnchor.constraint(equalTo: periodBar.centerYAnchor),

            monthLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            monthLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -5),
            monthLabel.widthAnchor.constraint(equalToConstant: barWidth + 20)
        ])
    }
    private func createLegendItem(color: UIColor, name: String) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let dot = UIView()
        dot.backgroundColor = color
        dot.layer.cornerRadius = 4
        dot.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        label.text = name
        label.font = .systemFont(ofSize: 11, weight: .medium)
        label.textColor = color
        label.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(dot)
        container.addSubview(label)

        NSLayoutConstraint.activate([
            dot.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            dot.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            dot.widthAnchor.constraint(equalToConstant: 8),
            dot.heightAnchor.constraint(equalToConstant: 8),

            label.leadingAnchor.constraint(equalTo: dot.trailingAnchor, constant: 6),
            label.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor)
        ])

        return container
    }

}
