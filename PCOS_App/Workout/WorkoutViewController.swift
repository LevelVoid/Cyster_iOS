import UIKit
import TipKit

class WorkoutViewController: UIViewController {

    private var goalMinutes:   Double = 20
    private var goalCalories:  Double = 300
    private var goalSteps:     Double = 8000

    private var cards: [Card] = []   
    private var exploreRoutine: [Routine] = []
    private var currentPhase: Phase = .unknown
    private var recommendedRoutineId: UUID?

    private var selectedPredefinedRoutine: Routine?
    private var selectedRoutine: Routine?

    private let routineDataStore = UserRoutineDataStore.shared
    private var routines: [Routine] = []

    @IBOutlet weak var collectionView: UICollectionView!

    private var walkthroughOverlay: WalkthroughOverlayView?
    private var isShowingWalkthroughCongrats: Bool = false
    private weak var tipPopover: UIViewController?
    private var hasShownWalkthroughThisSession = false

    override func viewDidLoad() {
        super.viewDidLoad()

        collectionView.accessibilityIdentifier = "workout_collectionView"

        cards = [
            Card(name: "Duration",   image: "clock.fill",     toBeDone: goalMinutes,  done: 0, unit: "min"),
            Card(name: "Cals burnt", image: "flame.fill",      toBeDone: goalCalories, done: 0, unit: "kcal"),
            Card(name: "Steps",      image: "shoeprints.fill", toBeDone: goalSteps,    done: 0)
        ]

        title = "Workout"
        navigationController?.navigationBar.prefersLargeTitles = true

        setupNavigation()
        registerCells()
        collectionView.setCollectionViewLayout(generateLayout(), animated: true)
        collectionView.dataSource = self
        collectionView.delegate = self

        let longPressGesture = UILongPressGestureRecognizer(
                target: self,
                action: #selector(handleLongPress(_:))
            )
            longPressGesture.minimumPressDuration = 0.5
            collectionView.addGestureRecognizer(longPressGesture)
    }

    private func setupNavigation() {
        let calendar = UIBarButtonItem(image: UIImage(systemName: "calendar"), style: .plain, target: self, action: #selector(calendarTapped))
        navigationItem.rightBarButtonItem = calendar
    }

    @objc func calendarTapped() {
        if let vc = storyboard?.instantiateViewController(withIdentifier: "WorkoutCalendarViewController") as? WorkoutCalendarViewController {
            navigationController?.pushViewController(vc, animated: true)
        }
    }

    func generateLayout() -> UICollectionViewLayout {
        let configuration = UICollectionViewCompositionalLayoutConfiguration()
        configuration.interSectionSpacing = 16

        let layout = UICollectionViewCompositionalLayout(sectionProvider: { (sectionIndex: Int, env: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? in

            let headerSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .absolute(sectionIndex == 0 ? 10 : 40)
            )
            let headerItem = NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: headerSize,
                elementKind: "header",
                alignment: .top
            )

            if sectionIndex == 0 {

                let itemSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0 / 3.0),
                    heightDimension: .absolute(160)
                )
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                item.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 4)

                let groupSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .estimated(160)
                )
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: -10, leading: 16, bottom: 0, trailing: 16) 
                section.boundarySupplementaryItems = [headerItem]
                return section

            } else if sectionIndex == 1 {

                let isEmpty = UserRoutineDataStore.shared.loadAll().isEmpty

                let itemSize = NSCollectionLayoutSize(
                    widthDimension: isEmpty ? .fractionalWidth(1.0) : .absolute(160),
                    heightDimension: .absolute(150)
                )
                let item = NSCollectionLayoutItem(layoutSize: itemSize)

                let groupSize = NSCollectionLayoutSize(
                    widthDimension: isEmpty ? .fractionalWidth(1.0) : .absolute(160),
                    heightDimension: .absolute(150)
                )
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
                let section = NSCollectionLayoutSection(group: group)
                section.orthogonalScrollingBehavior = isEmpty ? .none : .groupPaging
                section.interGroupSpacing = 12
                section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)
                section.boundarySupplementaryItems = [headerItem]
                return section

            } else {
                let itemSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .absolute(140)
                )
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                item.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 12, trailing: 0)

                let groupSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .absolute(140)
                )
                let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])

                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)
                section.interGroupSpacing = 0
                section.boundarySupplementaryItems = [headerItem]
                return section
            }
        }, configuration: configuration)

        return layout
    }

    func registerCells() {
        collectionView.register(UINib(nibName: "GoalCards", bundle: nil), forCellWithReuseIdentifier: "workout_Goal_Cell")
        collectionView.register(UINib(nibName: "ExploreRoutinesCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "explore_routines_cell")
        collectionView.register(UINib(nibName: "MyRoutinesEmptyCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "my_routines_empty_cell")
        collectionView.register(UINib(nibName: "MyRoutinesCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "my_routines_cell")
        collectionView.register(
            UINib(nibName: "HeaderCollectionReusableView", bundle: nil),
            forSupplementaryViewOfKind: "header",
            withReuseIdentifier: "header_cell"
        )
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "PredefinedRoutines" {
            if let vc = segue.destination as? PredefinedRoutinesViewController {
                vc.routine = selectedPredefinedRoutine
            }
        }

        if segue.identifier == "showRoutinePreview",
           let vc = segue.destination as? RoutinePreviewViewController,
           let routine = selectedRoutine {
            vc.routine = routine
        }
    }
}

extension WorkoutViewController: UICollectionViewDataSource, UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 0 {
            return cards.count
        } else if section == 1 {
            let count = UserRoutineDataStore.shared.loadAll().count

            return count == 0 ? 1 : count + 1
        } else {
            return exploreRoutine.count
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.section == 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "workout_Goal_Cell", for: indexPath) as! GoalCards
            cell.configureCell(cards[indexPath.row])
            return cell

        } else if indexPath.section == 1 {
            let routines = UserRoutineDataStore.shared.loadAll()

            if routines.isEmpty {
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: "my_routines_empty_cell",
                    for: indexPath
                ) as! MyRoutinesEmptyCollectionViewCell
                return cell
            } else {
                if indexPath.item != routines.count {
                    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "my_routines_cell", for: indexPath) as! MyRoutinesCollectionViewCell
                    let routine = routines[indexPath.row]
                    cell.configureCell(with: routine)
                    return cell
                } else {
                    let cell = collectionView.dequeueReusableCell(
                        withReuseIdentifier: "my_routines_empty_cell",
                        for: indexPath
                    ) as! MyRoutinesEmptyCollectionViewCell
                    return cell
                }
            }

        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "explore_routines_cell", for: indexPath) as! ExploreRoutinesCollectionViewCell
            let routine = exploreRoutine[indexPath.row]
            let isRecommended = routine.id == recommendedRoutineId
            cell.configureCell(routine, isRecommended: isRecommended)
            return cell
        }
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 3
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: "header", withReuseIdentifier: "header_cell", for: indexPath) as! HeaderCollectionReusableView

        if indexPath.section == 0 {
            headerView.configureHeader(with: "")
        } else if indexPath.section == 1 {
            headerView.configureHeader(with: "My Created Routines")
        } else if indexPath.section == 2 {
            headerView.configureHeader(with: "Routines You Could Try")
        }
        return headerView
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch indexPath.section {
        case 0:
            let selectedCard = cards[indexPath.item]
            navigateToMetrics(for: selectedCard)

        case 1:
            let routines = UserRoutineDataStore.shared.loadAll()
            if routines.isEmpty {
                if indexPath.item == 0 {
                    performSegue(withIdentifier: "showCreateRoutine", sender: nil)
                }
            } else {
                if indexPath.item < routines.count {
                    let routine = routines[indexPath.item]
                    selectedRoutine = routine
                    performSegue(withIdentifier: "showRoutinePreview", sender: nil)
                } else {
                    performSegue(withIdentifier: "showCreateRoutine", sender: nil)
                }
            }

        case 2:
            let routine = exploreRoutine[indexPath.item]
            selectedRoutine = routine
            performSegue(withIdentifier: "showRoutinePreview", sender: nil)

        default:
            return
        }
    }

    private func navigateToMetrics(for card: Card) {
        let goalType: GoalType
        switch card.name {
        case "Cals burnt": goalType = .calories
        case "Steps":      goalType = .steps
        case "Duration":   goalType = .duration
        default:           return
        }
        if let metricsVC = storyboard?.instantiateViewController(withIdentifier: "MetricsViewController") as? MetricsViewController {
            metricsVC.goalType = goalType
            navigationController?.pushViewController(metricsVC, animated: true)
        }
    }

    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        let point = gesture.location(in: collectionView)
        guard let indexPath = collectionView.indexPathForItem(at: point) else { return }
        guard indexPath.section == 1 else { return }
        let routines = UserRoutineDataStore.shared.loadAll()
        guard !routines.isEmpty, indexPath.item < routines.count else { return }
        let routine = routines[indexPath.item]

        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        showDeleteAlert(for: routine, at: indexPath)
    }

    private func showDeleteAlert(for routine: Routine, at indexPath: IndexPath) {
        let alert = UIAlertController(
            title: "Delete Routine?",
            message: "This routine will be permanently deleted.",
            preferredStyle: .alert
        )
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { _ in
            let routines = UserRoutineDataStore.shared.loadAll()
            if indexPath.item < routines.count { UserRoutineDataStore.shared.delete(routines[indexPath.item]) }
            self.collectionView.reloadSections(IndexSet(integer: 1))
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alert.addAction(cancelAction)
        alert.addAction(deleteAction)
        present(alert, animated: true)
    }
}

extension WorkoutViewController {

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if let profile = ProfileService.shared.buildUserProfile() {
            let workoutGoals = GoalEngine.generateGoals(for: profile).workout

            goalMinutes  = Double(Int(round(Double(workoutGoals.startingMinutesPerDay) / 5.0)) * 5)
            goalCalories = Double(Int(round(Double(workoutGoals.caloriesBurnedPerDay)  / 10.0)) * 10)
            goalSteps    = Double(Int(round(Double(workoutGoals.startingStepsPerDay)   / 100.0)) * 100)
        }

        cards = [
            Card(name: "Duration",   image: "clock.fill",     toBeDone: goalMinutes,  done: 0, unit: "min"),
            Card(name: "Cals burnt", image: "flame.fill",      toBeDone: goalCalories, done: 0, unit: "kcal"),
            Card(name: "Steps",      image: "shoeprints.fill", toBeDone: goalSteps,    done: 0)
        ]

        currentPhase = CycleDataStore.shared.currentPhaseInfo().phase

        var routinesList = RoutineDataStore.shared.routines(for: currentPhase)
        let recommended = RoutineDataStore.shared.recommendedRoutine(for: currentPhase)
        recommendedRoutineId = recommended.id

        if let index = routinesList.firstIndex(where: { $0.id == recommended.id }) {
            let item = routinesList.remove(at: index)
            routinesList.insert(item, at: 0)
        }
        exploreRoutine = routinesList

        syncWorkoutsToActivityStore()

        loadCardsFromDailyContext()

        collectionView.reloadData()

        fetchHealthKitData()

        handleWalkthroughOnAppear()
    }

    private func syncWorkoutsToActivityStore() {
        DailyActivityDataStore.shared.syncAllWorkouts()
    }

    private func fetchHealthKitData() {
        var hkSteps: Int = 0
        var hkCalories: Double = 0
        let group = DispatchGroup()

        group.enter()
        HealthKitManager.shared.fetchTodaySteps { steps in
            hkSteps = steps
            group.leave()
        }

        group.enter()
        HealthKitManager.shared.fetchTodayActiveCalories { cals in
            hkCalories = cals
            group.leave()
        }

        group.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            DailyActivityDataStore.shared.mergeHealthKitData(
                steps: hkSteps,
                    healthKitDailyCalories: Int(hkCalories)
            )
            self.loadCardsFromDailyContext()
            self.collectionView.reloadData()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        walkthroughOverlay?.dismiss(animated: false)
        walkthroughOverlay = nil
        tipPopover?.dismiss(animated: false)
    }

    private func loadCardsFromDailyContext() {
        let todayActivity = DailyActivityDataStore.shared.loadAll()
            .first(where: { Calendar.current.isDateInToday($0.date) })

        let durationMinutes = (todayActivity?.activeDurationSeconds ?? 0) / 60
        cards[0].done = Double(durationMinutes)

        cards[1].done = Double(todayActivity?.totalCalories ?? 0)

        cards[2].done = Double(todayActivity?.steps ?? 0)
    }
}

extension WorkoutViewController: WalkthroughManagerDelegate {

    func handleWalkthroughOnAppear() {
        guard WalkthroughManager.shared.isActive,
              !isShowingWalkthroughCongrats else { return }

        WalkthroughManager.shared.addDelegate(self)
        let step = WalkthroughManager.shared.currentStep

        if step == .workoutIntro {
            guard walkthroughOverlay == nil else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.showCreateRoutineWalkthroughOverlay()
            }
        } else if step == .workoutPremade {

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.showPremadeRoutineWalkthroughOverlay()
            }
        }
    }

    func walkthroughDidReachStep(_ step: WalkthroughStep) {
        guard isViewLoaded, view.window != nil else { return }
        if step == .workoutIntro {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.showCreateRoutineWalkthroughOverlay()
            }
        } else if step == .workoutPremade {

            walkthroughOverlay?.dismiss(animated: false)
            walkthroughOverlay = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
                self?.showPremadeRoutineWalkthroughOverlay()
            }
        } else if step == .chatbotPrompt {
            walkthroughOverlay?.dismiss()
            walkthroughOverlay = nil
        }
    }

    func walkthroughDidComplete() {
        walkthroughOverlay?.dismiss()
        walkthroughOverlay = nil
    }

    private func showCreateRoutineWalkthroughOverlay() {
        guard WalkthroughManager.shared.isActive,
              WalkthroughManager.shared.currentStep == .workoutIntro,
              view.window != nil else { return }

        let routinesCount = UserRoutineDataStore.shared.loadAll().count
        let targetIndexPath = IndexPath(item: routinesCount, section: 1)

        collectionView.scrollToItem(at: targetIndexPath, at: .centeredHorizontally, animated: false)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            guard let self = self else { return }
            guard let cell = self.collectionView.cellForItem(at: targetIndexPath),
                  let window = self.view.window else {

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                    self?.showCreateRoutineWalkthroughOverlay()
                }
                return
            }

            let cellFrame = cell.convert(cell.bounds, to: window)

            self.walkthroughOverlay?.dismiss(animated: false)
            self.walkthroughOverlay = WalkthroughOverlayView.install(
                in: window,
                targetFrame: cellFrame,
                onTargetTapped: { [weak self] in
                    guard let self = self else { return }
                    self.tipPopover?.dismiss(animated: true)
                    self.walkthroughOverlay?.dismiss()
                    self.walkthroughOverlay = nil

                    WalkthroughManager.shared.advanceToStep(.workoutAddExercise)
                    self.performSegue(withIdentifier: "showCreateRoutine", sender: nil)
                }
            )

            if #available(iOS 17.0, *) {
                let tip = CustomRoutineTip()
                if case .invalidated = tip.status {
                    WalkthroughManager.shared.advanceToStep(.workoutAddExercise)
                    return
                }
                let popoverVC = TipUIPopoverViewController(tip, sourceItem: cell)
                popoverVC.view.tintColor = UIColor(hex: "#FE7A96")
                if let overlay = self.walkthroughOverlay {
                    popoverVC.popoverPresentationController?.passthroughViews = [overlay]
                    overlay.observeTip(tip, popover: popoverVC) { [weak self] in
                        self?.walkthroughOverlay = nil
                        WalkthroughManager.shared.handleWalkthroughAborted()
                    }
                }
                self.tipPopover = popoverVC
                self.present(popoverVC, animated: true)
            }
        }
    }

    private func showPremadeRoutineWalkthroughOverlay() {
        guard WalkthroughManager.shared.isActive,
              WalkthroughManager.shared.currentStep == .workoutPremade,
              view.window != nil else { return }

        let targetIndexPath = IndexPath(item: 0, section: 2)

        collectionView.scrollToItem(at: targetIndexPath, at: .top, animated: false)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self = self else { return }
            guard let cell = self.collectionView.cellForItem(at: targetIndexPath),
                  let window = self.view.window else {

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                    self?.showPremadeRoutineWalkthroughOverlay()
                }
                return
            }

            let cellFrame = cell.convert(cell.bounds, to: window)

            self.walkthroughOverlay?.dismiss(animated: false)
            self.walkthroughOverlay = WalkthroughOverlayView.install(
                in: window,
                targetFrame: cellFrame,
                onTargetTapped: { [weak self] in
                    guard let self = self else { return }
                    self.tipPopover?.dismiss(animated: true)
                    self.walkthroughOverlay?.dismiss()
                    self.walkthroughOverlay = nil

                    WalkthroughManager.shared.advanceToStep(.chatbotPrompt)

                    self.collectionView(self.collectionView, didSelectItemAt: targetIndexPath)
                }
            )

            if #available(iOS 17.0, *) {
                let tip = RecommendedRoutineTip()
                if case .invalidated = tip.status {
                    WalkthroughManager.shared.advanceToStep(.chatbotPrompt)
                    return
                }
                let popoverVC = TipUIPopoverViewController(tip, sourceItem: cell)
                popoverVC.view.tintColor = UIColor(hex: "#FE7A96")
                if let overlay = self.walkthroughOverlay {
                    popoverVC.popoverPresentationController?.passthroughViews = [overlay]
                    overlay.observeTip(tip, popover: popoverVC) { [weak self] in
                        self?.walkthroughOverlay = nil
                        WalkthroughManager.shared.handleWalkthroughAborted()
                    }
                }
                self.tipPopover = popoverVC
                self.present(popoverVC, animated: true)
            }
        }
    }
}
