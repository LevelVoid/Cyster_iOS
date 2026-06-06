import UIKit

class SymptomPatternsCollectionViewCell:
    UICollectionViewCell,

    UICollectionViewDelegate {

    @IBOutlet weak var collectionView: UICollectionView!

    @IBOutlet weak var  NameLabel: UILabel!
@IBOutlet weak var  SymptomImage: UIImageView!
        @IBOutlet  var  StartDateLabels: [UILabel]!
        @IBOutlet  var  LengthLabels: [UILabel]!
        @IBOutlet var ovulationView:UIView!
        @IBOutlet var follicularView:UIView!
        @IBOutlet var leutalView:UIView!
        @IBOutlet var menstrualView:UIView!
        @IBOutlet weak var insightLabel: UILabel!

    private var symptom: SymptomItem?

    private var cycles: [CycleData] = []

    private var currentInsightTask: Task<Void, Never>?

    private var emptyStateContainer: UIView!

        override func awakeFromNib() {
            super.awakeFromNib()

            contentView.layer.cornerRadius = 20
            contentView.backgroundColor = UIColor.systemBackground
            contentView.layer.masksToBounds = true

            SymptomImage.layer.cornerRadius = 12
            SymptomImage.clipsToBounds = true

            menstrualView.backgroundColor = Phase.menstrual.backgroundColor.withAlphaComponent(0.5)
            follicularView.backgroundColor = Phase.follicular.backgroundColor.withAlphaComponent(0.5)
            ovulationView.backgroundColor = Phase.ovulation.backgroundColor.withAlphaComponent(0.5)
            leutalView.backgroundColor = Phase.luteal.backgroundColor.withAlphaComponent(0.5)

            [menstrualView, follicularView, ovulationView, leutalView].forEach {
                $0?.layer.cornerRadius = ($0?.bounds.width ?? 0) / 2
            }

            setupCollectionView()
            setupEmptyStateView()
        }

    private var collectionViewHeightConstraint: NSLayoutConstraint?

    private func setupCollectionView() {
        collectionView.collectionViewLayout = makeLayout()
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.register(
                UINib(nibName: "DayCircleCollectionViewCell", bundle: nil),
                forCellWithReuseIdentifier: "DayCircleCollectionViewCell"
            )
        collectionView.alwaysBounceVertical = false
        collectionView.alwaysBounceHorizontal = true
        collectionView.isDirectionalLockEnabled = true

    }

     private func setupEmptyStateView() {
        emptyStateContainer = UIView()
        emptyStateContainer.translatesAutoresizingMaskIntoConstraints = false
        emptyStateContainer.isHidden = true
        emptyStateContainer.backgroundColor = UIColor.systemBackground
        contentView.addSubview(emptyStateContainer)

        NSLayoutConstraint.activate([
            emptyStateContainer.topAnchor.constraint(equalTo: contentView.topAnchor),
            emptyStateContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            emptyStateContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            emptyStateContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])

        let iconContainer = UIView()
        iconContainer.translatesAutoresizingMaskIntoConstraints = false
        iconContainer.backgroundColor = UIColor.systemGray6
        iconContainer.layer.cornerRadius = 25
        iconContainer.clipsToBounds = true
        emptyStateContainer.addSubview(iconContainer)

        let headerIcon = UIImageView()
        headerIcon.translatesAutoresizingMaskIntoConstraints = false
        headerIcon.image = UIImage(systemName: "cross.case")?
            .withConfiguration(UIImage.SymbolConfiguration(pointSize: 22, weight: .light))
        headerIcon.tintColor = .systemGray3
        headerIcon.contentMode = .scaleAspectFit
        iconContainer.addSubview(headerIcon)

        let headerTitle = UILabel()
        headerTitle.translatesAutoresizingMaskIntoConstraints = false
        headerTitle.text = "No Symptom Logged"
        headerTitle.font = .systemFont(ofSize: 17, weight: .regular)
        headerTitle.textColor = .label
        emptyStateContainer.addSubview(headerTitle)

        let headerSubtitle = UILabel()
        headerSubtitle.translatesAutoresizingMaskIntoConstraints = false
        headerSubtitle.text = "Log a symptom to view patterns"
        headerSubtitle.font = .systemFont(ofSize: 13)
        headerSubtitle.textColor = .secondaryLabel
        emptyStateContainer.addSubview(headerSubtitle)

        let separator = UIView()
        separator.translatesAutoresizingMaskIntoConstraints = false
        separator.backgroundColor = UIColor.separator.withAlphaComponent(0.2)
        emptyStateContainer.addSubview(separator)

        let circleColors: [UIColor] = [
            Phase.menstrual.backgroundColor.withAlphaComponent(0.5),
            Phase.follicular.backgroundColor.withAlphaComponent(0.5),
            Phase.ovulation.backgroundColor.withAlphaComponent(0.5),
            Phase.luteal.backgroundColor.withAlphaComponent(0.5)
        ]

        let circlesStack = UIStackView()
        circlesStack.translatesAutoresizingMaskIntoConstraints = false
        circlesStack.axis = .horizontal
        circlesStack.spacing = 14
        circlesStack.alignment = .center
        emptyStateContainer.addSubview(circlesStack)

        let circleSize: CGFloat = 32
        for color in circleColors {
            let circle = UIView()
            circle.translatesAutoresizingMaskIntoConstraints = false
            circle.backgroundColor = color
            circle.layer.cornerRadius = circleSize / 2
            NSLayoutConstraint.activate([
                circle.widthAnchor.constraint(equalToConstant: circleSize),
                circle.heightAnchor.constraint(equalToConstant: circleSize)
            ])
            circlesStack.addArrangedSubview(circle)
        }

        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "No Data Yet"
        titleLabel.font = .systemFont(ofSize: 16, weight: .regular)
        titleLabel.textColor = .label
        titleLabel.textAlignment = .center
        emptyStateContainer.addSubview(titleLabel)

        let subtitleLabel = UILabel()
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.text = "Log your symptoms daily to see\nhow they change across your cycle\nphases"
        subtitleLabel.font = .systemFont(ofSize: 13)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0
        emptyStateContainer.addSubview(subtitleLabel)

        NSLayoutConstraint.activate([

            iconContainer.topAnchor.constraint(equalTo: emptyStateContainer.topAnchor, constant: 12),
            iconContainer.leadingAnchor.constraint(equalTo: emptyStateContainer.leadingAnchor, constant: 12),
            iconContainer.widthAnchor.constraint(equalToConstant: 50),
            iconContainer.heightAnchor.constraint(equalToConstant: 50),

            headerIcon.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor),
            headerIcon.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor),
            headerIcon.widthAnchor.constraint(equalToConstant: 24),
            headerIcon.heightAnchor.constraint(equalToConstant: 24),

            headerTitle.topAnchor.constraint(equalTo: iconContainer.topAnchor, constant: 4),
            headerTitle.leadingAnchor.constraint(equalTo: iconContainer.trailingAnchor, constant: 12),
            headerTitle.trailingAnchor.constraint(equalTo: emptyStateContainer.trailingAnchor, constant: -12),

            headerSubtitle.topAnchor.constraint(equalTo: headerTitle.bottomAnchor, constant: 2),
            headerSubtitle.leadingAnchor.constraint(equalTo: headerTitle.leadingAnchor),
            headerSubtitle.trailingAnchor.constraint(equalTo: headerTitle.trailingAnchor),

            separator.topAnchor.constraint(equalTo: iconContainer.bottomAnchor, constant: 8),
            separator.leadingAnchor.constraint(equalTo: emptyStateContainer.leadingAnchor, constant: 12),
            separator.trailingAnchor.constraint(equalTo: emptyStateContainer.trailingAnchor, constant: -12),
            separator.heightAnchor.constraint(equalToConstant: 0.5),

            circlesStack.centerXAnchor.constraint(equalTo: emptyStateContainer.centerXAnchor),
            circlesStack.topAnchor.constraint(equalTo: separator.bottomAnchor, constant: 35),

            titleLabel.topAnchor.constraint(equalTo: circlesStack.bottomAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: emptyStateContainer.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: emptyStateContainer.trailingAnchor, constant: -16),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
            subtitleLabel.leadingAnchor.constraint(equalTo: emptyStateContainer.leadingAnchor, constant: 16),
            subtitleLabel.trailingAnchor.constraint(equalTo: emptyStateContainer.trailingAnchor, constant: -16)
        ])
    }

    func configureEmptyState() {
        currentInsightTask?.cancel()
        emptyStateContainer.isHidden = false

        setDataViewsHidden(true)
    }

    private func setDataViewsHidden(_ hidden: Bool) {

        if let dataContainer = contentView.subviews.first {
            dataContainer.isHidden = hidden
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        setDataViewsHidden(true)
        emptyStateContainer.isHidden = true
        currentInsightTask?.cancel()
        insightLabel.text = nil
    }

        func configure(cycles: [CycleData], symptom: SymptomItem) {
            emptyStateContainer.isHidden = true

            setDataViewsHidden(false)

            self.symptom = symptom

            self.cycles = Array(cycles.prefix(3))

            NameLabel.numberOfLines = 0

            let nameAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 17, weight: .medium),
                .foregroundColor: UIColor.label
            ]
            let categoryAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 13, weight: .regular),
                .foregroundColor: UIColor.secondaryLabel
            ]

            let attrString = NSMutableAttributedString(string: symptom.name + "\n", attributes: nameAttrs)
            attrString.append(NSAttributedString(string: symptom.category, attributes: categoryAttrs))

            NameLabel.attributedText = attrString

            let canonicalIcon = SymptomCategory.allCategories
                .flatMap { $0.items }
                .first(where: { $0.name == symptom.name })?.icon ?? symptom.icon

            SymptomImage.image = UIImage(named: canonicalIcon)

            for i in 0..<StartDateLabels.count {
                if i < self.cycles.count {
                    let cycle = self.cycles[i]

                    let formatter = DateFormatter()
                    formatter.dateFormat = "MMM d"
                    StartDateLabels[i].text = formatter.string(from: cycle.startDate)
                    LengthLabels[i].text = "\(cycle.days.count) days"
                } else {
                    StartDateLabels[i].text = ""
                    LengthLabels[i].text = ""
                }
            }

            let rows = self.cycles.count + 1   
            let gridHeight = CGFloat(rows) * 44
            if let existing = collectionViewHeightConstraint {
                existing.constant = gridHeight
            } else {

                if let constraint = collectionView.constraints.first(where: { $0.firstAttribute == .height }) {
                    constraint.constant = gridHeight
                    collectionViewHeightConstraint = constraint
                }
            }

            collectionView.collectionViewLayout.invalidateLayout()
            collectionView.reloadData()

            currentInsightTask?.cancel()

            if let cached = SymptomInsightModel.shared.cachedInsight(for: symptom.name, cycles: cycles) {
                insightLabel.text = cached
                insightLabel.textColor = .darkGray
            } else {
                insightLabel.text = "Generating insight…"
                insightLabel.textColor = .secondaryLabel
            }

            currentInsightTask = Task { [weak self] in
                guard let self = self else { return }
                do {
                    let insight = try await SymptomInsightModel.shared.fetchSymptomInsight(
                        symptomName: symptom.name,
                        cycles: cycles
                    )

                    if !Task.isCancelled {
                        await MainActor.run {
                            self.insightLabel.text = insight
                            self.insightLabel.textColor = .black
                        }
                    }
                } catch {
                    if !Task.isCancelled {
                        await MainActor.run {
                            self.insightLabel.text = "Insight unavailable at this time."
                            self.insightLabel.textColor = .secondaryLabel
                        }
                    }
                }
            }
        }

        private func makeLayout() -> UICollectionViewLayout {
            UICollectionViewCompositionalLayout { [weak self] _, _ in
                guard let self = self else { return nil }

                let rows = self.cycles.count + 1   
                let columns = self.maxDayCount()

                let itemSize = NSCollectionLayoutSize(
                    widthDimension: .absolute(26),
                    heightDimension: .absolute(26)
                )
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                let rowGroupSize = NSCollectionLayoutSize(
                    widthDimension: .estimated(CGFloat(columns) * 30),
                    heightDimension: .absolute(30)
                )

                let rowGroup = NSCollectionLayoutGroup.horizontal(
                    layoutSize: rowGroupSize,
                    repeatingSubitem: item,
                    count: columns
                )
                rowGroup.interItemSpacing = .fixed(4)

                let gridGroupSize = NSCollectionLayoutSize(
                    widthDimension: .estimated(CGFloat(columns) * 30),
                    heightDimension: .absolute(CGFloat(rows) * 42)
                )
                let gridGroup = NSCollectionLayoutGroup.vertical(
                    layoutSize: gridGroupSize,
                    repeatingSubitem: rowGroup,
                    count: rows
                )

                let section = NSCollectionLayoutSection(group: gridGroup)
                section.interGroupSpacing = 0

                return section
            }
        }
}

extension SymptomPatternsCollectionViewCell: UICollectionViewDataSource {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        1

    }

    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {

        return (cycles.count + 1) * maxDayCount()
    }
    private func maxDayCount() -> Int {
        max(cycles.map { $0.days.count }.max() ?? 1, 1)
    }

}
extension SymptomPatternsCollectionViewCell {

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "DayCircleCollectionViewCell",
            for: indexPath
        ) as! DayCircleCollectionViewCell

        let totalColumns = maxDayCount()
        let row = indexPath.item / totalColumns
        let column = indexPath.item % totalColumns

        if row == 0 {

            cell.configureAsDayNumber(day: column + 1)
        } else {
            let cycleIndex = row - 1
            let cycle = cycles[cycleIndex]

            if column < cycle.days.count {
                let day = cycle.days[column]

                let actualDate = Calendar.current.date(
                    byAdding: .day,
                    value: column,
                    to: cycle.startDate
                ) ?? cycle.startDate

                let liveSymptoms = SymptomDataStore.loadSymptoms(for: actualDate)
                let matchedSymptom = liveSymptoms.first { $0.name == symptom?.name }

                cell.configure(
                    day: day,
                    symptom: matchedSymptom,
                    focusedSymptom: symptom
                )
            } else {

                cell.prepareForReuse()
                cell.circleView.isHidden = true
                cell.circleView.backgroundColor = .clear
            }
        }

        return cell
    }

}

