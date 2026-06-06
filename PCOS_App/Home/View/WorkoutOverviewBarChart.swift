import UIKit

class WorkoutOverviewBarChart: UIView {

    struct SegmentData {
        let name: String
        let value: Int
        let color: UIColor
    }

    private let containerView = UIView()
    private var segments: [SegmentData] = []
    private var total: Int = 0

    private let barHeight: CGFloat = 45
    private let cornerRadius: CGFloat = 10

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        backgroundColor = .clear

        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.layer.cornerRadius = cornerRadius
        containerView.clipsToBounds = true

        addSubview(containerView)

        setupConstraints()
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.heightAnchor.constraint(equalToConstant: barHeight),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    func configure(with segmentData: [SegmentData]) {
        self.segments = segmentData
        self.total = segmentData.reduce(0) { $0 + $1.value }

        containerView.subviews.forEach { $0.removeFromSuperview() }

        guard total > 0 else { return }

        var previousSegmentView: UIView?

        for (index, segment) in segments.enumerated() {
            let percentage = CGFloat(segment.value) / CGFloat(total)

            let segmentView = UIView()
            segmentView.backgroundColor = segment.color
            segmentView.translatesAutoresizingMaskIntoConstraints = false
            containerView.addSubview(segmentView)

            if index == 0 {

                NSLayoutConstraint.activate([
                    segmentView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                    segmentView.topAnchor.constraint(equalTo: containerView.topAnchor),
                    segmentView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
                    segmentView.widthAnchor.constraint(equalTo: containerView.widthAnchor, multiplier: percentage)
                ])

                segmentView.layer.cornerRadius = cornerRadius
                segmentView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
            } else {

                NSLayoutConstraint.activate([
                    segmentView.leadingAnchor.constraint(equalTo: previousSegmentView!.trailingAnchor),
                    segmentView.topAnchor.constraint(equalTo: containerView.topAnchor),
                    segmentView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
                    segmentView.widthAnchor.constraint(equalTo: containerView.widthAnchor, multiplier: percentage)
                ])

                if index == segments.count - 1 {
                    segmentView.layer.cornerRadius = cornerRadius
                    segmentView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
                }
            }

            previousSegmentView = segmentView
        }
    }
}

class WorkoutProgressBarCardView: UIView {

    private let progressBar = WorkoutOverviewBarChart()

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

        progressBar.translatesAutoresizingMaskIntoConstraints = false

        addSubview(progressBar)

        setupConstraints()
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            progressBar.topAnchor.constraint(equalTo: topAnchor),
            progressBar.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            progressBar.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            progressBar.bottomAnchor.constraint(equalTo: bottomAnchor),
            progressBar.heightAnchor.constraint(equalToConstant: 45)
        ])
    }

    func configure(with segments: [WorkoutOverviewBarChart.SegmentData]) {
        progressBar.configure(with: segments)
    }
}
