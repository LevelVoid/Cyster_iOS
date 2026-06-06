import UIKit

class CyclePatternCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var cyclePatternView: UIView!
    @IBOutlet weak var CycleLengthView: UIView!
    @IBOutlet weak var PeriodLengthView: UIView!
    @IBOutlet weak var viewTooTiredToRemove: UIView!
    @IBOutlet weak var periodCycleChartView: PeriodCycleChartView!

    @IBOutlet weak var avgCycleLengthLabel: UILabel!
    @IBOutlet weak var avgPeriodLengthLabel: UILabel!

    private var observationLabel: UILabel!
    private var loadingIndicator: UIActivityIndicatorView!

    private var emptyStateContainer: UIView!

    private var currentInsightFetchTask: Task<Void, Never>?
    private var cachedInsight: String?
    private var lastCycleCount: Int = -1

    override func layoutSubviews() {
        super.layoutSubviews()

        if observationLabel != nil {
            observationLabel.preferredMaxLayoutWidth = observationLabel.frame.width
        }

        if emptyStateContainer != nil && !emptyStateContainer.isHidden {
            updateDashedBarLayers()
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        cyclePatternView.layer.cornerRadius = 20
        viewTooTiredToRemove.layer.cornerRadius = 20
        viewTooTiredToRemove.layer.borderWidth = 0

        CycleLengthView.layer.cornerRadius = 10
        PeriodLengthView.layer.cornerRadius = 10

        cyclePatternView.translatesAutoresizingMaskIntoConstraints = false
        viewTooTiredToRemove.translatesAutoresizingMaskIntoConstraints = false

        observationLabel = UILabel()
        observationLabel.translatesAutoresizingMaskIntoConstraints = false
        observationLabel.font = .systemFont(ofSize: 14)
        observationLabel.textColor = .label
        observationLabel.numberOfLines = 0
        observationLabel.textAlignment = .left

        loadingIndicator = UIActivityIndicatorView(style: .medium)
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.hidesWhenStopped = true

        viewTooTiredToRemove.addSubview(observationLabel)
        viewTooTiredToRemove.addSubview(loadingIndicator)

        setupEmptyStateView()

        NSLayoutConstraint.activate([
            cyclePatternView.topAnchor.constraint(equalTo: contentView.topAnchor),
            cyclePatternView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            cyclePatternView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            cyclePatternView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            viewTooTiredToRemove.topAnchor.constraint(equalTo: cyclePatternView.topAnchor),
            viewTooTiredToRemove.leadingAnchor.constraint(equalTo: cyclePatternView.leadingAnchor),
            viewTooTiredToRemove.trailingAnchor.constraint(equalTo: cyclePatternView.trailingAnchor),
            viewTooTiredToRemove.bottomAnchor.constraint(equalTo: cyclePatternView.bottomAnchor),

            observationLabel.topAnchor.constraint(equalTo: periodCycleChartView.bottomAnchor, constant: 16),
            observationLabel.leadingAnchor.constraint(equalTo: viewTooTiredToRemove.leadingAnchor, constant: 16),
            observationLabel.trailingAnchor.constraint(equalTo: viewTooTiredToRemove.trailingAnchor, constant: -16),
            observationLabel.bottomAnchor.constraint(equalTo: viewTooTiredToRemove.bottomAnchor, constant: -20),

            loadingIndicator.centerYAnchor.constraint(equalTo: observationLabel.centerYAnchor),
            loadingIndicator.centerXAnchor.constraint(equalTo: viewTooTiredToRemove.centerXAnchor)
        ])
    }

    private func setupEmptyStateView() {
        emptyStateContainer = UIView()
        emptyStateContainer.translatesAutoresizingMaskIntoConstraints = false
        emptyStateContainer.isHidden = true
        emptyStateContainer.backgroundColor = .clear
        viewTooTiredToRemove.addSubview(emptyStateContainer)

        NSLayoutConstraint.activate([
            emptyStateContainer.topAnchor.constraint(equalTo: periodCycleChartView.topAnchor),
            emptyStateContainer.leadingAnchor.constraint(equalTo: viewTooTiredToRemove.leadingAnchor, constant: 16),
            emptyStateContainer.trailingAnchor.constraint(equalTo: viewTooTiredToRemove.trailingAnchor, constant: -16),
            emptyStateContainer.bottomAnchor.constraint(equalTo: viewTooTiredToRemove.bottomAnchor, constant: -20)
        ])

        let barsContainer = UIView()
        barsContainer.translatesAutoresizingMaskIntoConstraints = false
        barsContainer.tag = 100 
        emptyStateContainer.addSubview(barsContainer)

        let barHeights: [CGFloat] = [90, 120, 70]
        let barWidth: CGFloat = 44
        let barSpacing: CGFloat = 16

        var previousBar: UIView? = nil
        for (index, height) in barHeights.enumerated() {
            let bar = UIView()
            bar.translatesAutoresizingMaskIntoConstraints = false
            bar.tag = 200 + index 
            bar.layer.cornerRadius = 6
            bar.backgroundColor = UIColor(red: 0.98, green: 0.93, blue: 0.93, alpha: 0.5)
            barsContainer.addSubview(bar)

            NSLayoutConstraint.activate([
                bar.bottomAnchor.constraint(equalTo: barsContainer.bottomAnchor),
                bar.widthAnchor.constraint(equalToConstant: barWidth),
                bar.heightAnchor.constraint(equalToConstant: height)
            ])

            if let prev = previousBar {
                bar.leadingAnchor.constraint(equalTo: prev.trailingAnchor, constant: barSpacing).isActive = true
            } else {
                bar.leadingAnchor.constraint(equalTo: barsContainer.leadingAnchor).isActive = true
            }

            previousBar = bar
        }

        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "Keep logging to see your trends"
        titleLabel.font = .systemFont(ofSize: 16, weight: .regular)
        titleLabel.textColor = .label
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        emptyStateContainer.addSubview(titleLabel)

        let subtitleLabel = UILabel()
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.text = "Your cycle patterns will appear here\nafter a few logs"
        subtitleLabel.font = .systemFont(ofSize: 13)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0
        emptyStateContainer.addSubview(subtitleLabel)

        let totalBarsWidth = (barWidth * 3) + (barSpacing * 2)
        NSLayoutConstraint.activate([
            barsContainer.centerXAnchor.constraint(equalTo: emptyStateContainer.centerXAnchor),
            barsContainer.topAnchor.constraint(equalTo: emptyStateContainer.topAnchor, constant: 35),
            barsContainer.widthAnchor.constraint(equalToConstant: totalBarsWidth),
            barsContainer.heightAnchor.constraint(equalToConstant: 120),

            titleLabel.topAnchor.constraint(equalTo: barsContainer.bottomAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: emptyStateContainer.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: emptyStateContainer.trailingAnchor, constant: -16),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: emptyStateContainer.leadingAnchor, constant: 16),
            subtitleLabel.trailingAnchor.constraint(equalTo: emptyStateContainer.trailingAnchor, constant: -16)
        ])
    }

    private func updateDashedBarLayers() {
        guard let barsContainer = emptyStateContainer.viewWithTag(100) else { return }

        let dashedColor = UIColor(red: 0.90, green: 0.75, blue: 0.78, alpha: 1.0).cgColor

        for index in 0..<3 {
            guard let bar = barsContainer.viewWithTag(200 + index) else { continue }

            bar.layer.sublayers?.removeAll(where: { $0.name == "dashedBorder" })

            let dashLayer = CAShapeLayer()
            dashLayer.name = "dashedBorder"
            dashLayer.strokeColor = dashedColor
            dashLayer.fillColor = UIColor.clear.cgColor
            dashLayer.lineWidth = 2
            dashLayer.lineDashPattern = [6, 4]
            dashLayer.path = UIBezierPath(roundedRect: bar.bounds, cornerRadius: 6).cgPath
            bar.layer.addSublayer(dashLayer)
        }
    }

    func configureEmptyState() {

        currentInsightFetchTask?.cancel()
        loadingIndicator.stopAnimating()

        avgCycleLengthLabel?.text = "--"
        avgPeriodLengthLabel?.text = "--"

        periodCycleChartView.isHidden = true
        observationLabel.isHidden = true
        emptyStateContainer.isHidden = false

        layoutIfNeeded()
        updateDashedBarLayers()
    }

    func refreshChart() {

        periodCycleChartView.isHidden = false
        observationLabel.isHidden = false
        emptyStateContainer.isHidden = true

        let cycles = CycleDataStore.shared.previousCycles(count: 6)
        let prediction = CycleDataStore.shared.nextPeriodPrediction

        periodCycleChartView.configure(with: cycles)

        if let avgCycle = prediction.averageCycleLength {
            avgCycleLengthLabel?.text = "\(avgCycle)"
        } else {
            avgCycleLengthLabel?.text = "—"
        }

        if let avgPeriod = prediction.averagePeriodLength {
            avgPeriodLengthLabel?.text = "\(avgPeriod)"
        } else {
            avgPeriodLengthLabel?.text = "—"
        }

        let cycleCount = cycles.count
        if let cached = cachedInsight, lastCycleCount == cycleCount {
            observationLabel.text = cached
            observationLabel.textColor = .label
            observationLabel.textAlignment = .left
            observationLabel.font = .systemFont(ofSize: 14)
            loadingIndicator.stopAnimating()
            return
        }

        observationLabel.text = "Generating your insights..."
        observationLabel.textColor = .secondaryLabel
        observationLabel.textAlignment = .center
        observationLabel.font = .systemFont(ofSize: 14)
        loadingIndicator.startAnimating()

        currentInsightFetchTask?.cancel()
        currentInsightFetchTask = Task {
            do {
                let insight = try await CycleObservationsModel.shared.fetchCycleInsight(cycles: cycles)
                guard !Task.isCancelled else { return }
                DispatchQueue.main.async { [weak self] in
                    self?.loadingIndicator.stopAnimating()
                    self?.observationLabel.text = insight
                    self?.observationLabel.textColor = .label
                    self?.observationLabel.textAlignment = .left
                    self?.observationLabel.font = .systemFont(ofSize: 14)
                    self?.cachedInsight = insight
                    self?.lastCycleCount = cycleCount

                    if let cv = self?.superview as? UICollectionView {
                        cv.performBatchUpdates(nil, completion: nil)
                    } else if let cv = self?.superview?.superview as? UICollectionView {
                        cv.performBatchUpdates(nil, completion: nil)
                    }
                }
            } catch {
                guard !Task.isCancelled else { return }
                DispatchQueue.main.async { [weak self] in
                    self?.loadingIndicator.stopAnimating()
                    self?.observationLabel.text = "Unable to generate cycle insights at this time."
                    self?.observationLabel.textColor = .secondaryLabel
                    self?.observationLabel.textAlignment = .center
                    self?.observationLabel.font = .systemFont(ofSize: 14)

                    if let cv = self?.superview as? UICollectionView {
                        cv.performBatchUpdates(nil, completion: nil)
                    } else if let cv = self?.superview?.superview as? UICollectionView {
                        cv.performBatchUpdates(nil, completion: nil)
                    }
                }
            }
        }
    }
}
