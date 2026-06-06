protocol DataPassDelegate: AnyObject {
    func passData(symptoms: [SymptomItem]) -> [SymptomItem]
}

import UIKit

class SymptomLoggerViewController: UIViewController {

    var logDate: Date = Date()  
    @IBOutlet weak var collectionView: UICollectionView!
    weak var delegate: DataPassDelegate?
    private var categories = SymptomCategory.allCategories
    private var selectedSymptoms: Set<IndexPath> = []

    var onSymptomsSelected: (([SymptomItem]) -> Void)?
    private var preSelectedSymptoms: [SymptomItem] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Today's Symptoms"
        navigationController?.navigationBar.prefersLargeTitles = false

        if let timestamps = UserDefaults.standard.array(forKey: "SavedPeriodDates") as? [TimeInterval] {
            let periodDates = Set(timestamps.map { Calendar.current.startOfDay(for: Date(timeIntervalSince1970: $0)) })
            let isPeriod = periodDates.contains(Calendar.current.startOfDay(for: logDate))
            if !isPeriod {
                categories.removeAll(where: { $0.title == "Flow" })
            }
        } else {
            categories.removeAll(where: { $0.title == "Flow" })
        }

        let doneButton = UIBarButtonItem(title: "Save", style: .prominent, target: self, action: #selector(doneButtonTapped(_:)))
        navigationItem.rightBarButtonItem = doneButton
        doneButton.tintColor = .white

        setupCollectionView()
        preselectSymptoms()

        view.backgroundColor = UIColor(hex: "#FCEEED")
        collectionView.backgroundColor = .clear
    }

    private func setupCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self

        collectionView.register(
            UINib(nibName: "SymptomItemCollectionViewCell", bundle: nil),
            forCellWithReuseIdentifier: SymptomItemCollectionViewCell.identifier
        )

        collectionView.register(
            UINib(nibName: "SymptomLogSectionHeaderView", bundle: nil),
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: "SymptomLogSectionHeaderView"
        )
        collectionView.collectionViewLayout = createCompositionalLayout()

        if let layout = collectionView.collectionViewLayout as? UICollectionViewCompositionalLayout {
            layout.register(SectionBackgroundDecorationView.self, forDecorationViewOfKind: "SectionBackground")
        }
    }

    func setSelectedSymptoms(_ symptoms: [SymptomItem]) {
        self.preSelectedSymptoms = symptoms
    }

    private func preselectSymptoms() {

        selectedSymptoms.removeAll()

        for symptom in preSelectedSymptoms {

            for (sectionIndex, category) in categories.enumerated() {
                if let itemIndex = category.items.firstIndex(where: { $0.name == symptom.name }) {
                    let indexPath = IndexPath(item: itemIndex, section: sectionIndex)
                    selectedSymptoms.insert(indexPath)
                }
            }
        }
        collectionView.reloadData()
    }

    @objc private func doneButtonTapped(_ sender: Any) {
        let symptoms = getSelectedSymptoms()

        if let delegate = self.delegate {
            _ = delegate.passData(symptoms: symptoms)
        } else {
            print("No delegate found")
        }

        if let navigationController = navigationController, navigationController.viewControllers.count > 1 {
            navigationController.popViewController(animated: true)
        } else {
            dismiss(animated: true)
                }
    }

    private func getSelectedSymptoms() -> [SymptomItem] {
        var symptoms: [SymptomItem] = []
        let sortedIndexPaths = selectedSymptoms.sorted {
            if $0.section != $1.section { return $0.section < $1.section }
            return $0.item < $1.item
        }

        let now = logDate

        for (index, indexPath) in sortedIndexPaths.enumerated() {
            let symptom = categories[indexPath.section].items[indexPath.item]
            let originalDate = preSelectedSymptoms.first(where: { $0.name == symptom.name })?.date ?? now.addingTimeInterval(TimeInterval(index))
            let logged = SymptomItem(
                name: symptom.name,
                icon: symptom.icon,
                isSelected: true,
                date: originalDate,
                category: symptom.category
            )
            symptoms.append(logged)
        }

        symptoms.sort { ($0.date ?? Date.distantPast) > ($1.date ?? Date.distantPast) }

        return symptoms
    }
}

extension SymptomLoggerViewController: UICollectionViewDataSource {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return categories.count
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return categories[section].items.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let dequeuedCell = collectionView.dequeueReusableCell(withReuseIdentifier: SymptomItemCollectionViewCell.identifier, for: indexPath)

        guard let cell = dequeuedCell as? SymptomItemCollectionViewCell else {
            return dequeuedCell 
        }

        let symptom = categories[indexPath.section].items[indexPath.item]
        let isSelected = selectedSymptoms.contains(indexPath)

        cell.configure(with: symptom, isSelected: isSelected)

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {

        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "SymptomLogSectionHeaderView", for: indexPath) as! SymptomLogSectionHeaderView
        header.SymptomSectionLabel.text = categories[indexPath.section].title
        return header
    }
}

extension SymptomLoggerViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {

        let selectedCategory = categories[indexPath.section].title

        if selectedSymptoms.contains(indexPath) {
            selectedSymptoms.remove(indexPath)
            collectionView.reloadItems(at: [indexPath])
            return
        }

        if selectedCategory == "Flow" || selectedCategory == "Discharge" {

            let previouslySelected = selectedSymptoms.filter { previousIndexPath in
                categories[previousIndexPath.section].title == selectedCategory
            }

            var cellsToReload = [indexPath]
            for previousIndexPath in previouslySelected {
                selectedSymptoms.remove(previousIndexPath)
                cellsToReload.append(previousIndexPath)
            }

            selectedSymptoms.insert(indexPath)

            collectionView.reloadItems(at: cellsToReload)
        } else {

            selectedSymptoms.insert(indexPath)
            collectionView.reloadItems(at: [indexPath])
        }
    }

    private func createCompositionalLayout() -> UICollectionViewLayout {
        return UICollectionViewCompositionalLayout { (sectionIndex, layoutEnvironment) -> NSCollectionLayoutSection? in
            return self.createGridSection()
        }
    }

    private func createGridSection() -> NSCollectionLayoutSection {

        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(0.25),  
            heightDimension: .fractionalHeight(1.0)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 6, bottom: 6, trailing: 6)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),   
            heightDimension: .absolute(128)           
        )
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: groupSize,
            repeatingSubitem: item,
            count: 4  
        )

        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(
            top: 20,
            leading: 16,
            bottom: 24,
            trailing: 16
        )

        let sectionBackground = NSCollectionLayoutDecorationItem.background(elementKind: "SectionBackground")
        sectionBackground.contentInsets = NSDirectionalEdgeInsets(top: 44, leading: 8, bottom: 8, trailing: 8)
        section.decorationItems = [sectionBackground]

        let headerSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(44)
        )
        let header = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: headerSize,
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .top
        )
        section.boundarySupplementaryItems = [header]

        return section
    }
}

