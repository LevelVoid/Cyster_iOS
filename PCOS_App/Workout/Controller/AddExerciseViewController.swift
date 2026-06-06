import UIKit

class AddExerciseViewController: UIViewController {

    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var addExerciseSearchBar: UISearchBar!
    @IBOutlet weak var muscleTypeFilterButton: UIButton!
    @IBOutlet weak var equipmentsFilterButton: UIButton!

    private var exercises: [Exercise] = []
    private var filteredExercises : [Exercise] = []

    var selectedExerciseIDs = Set<UUID>()

    var onExercisesSelected: (([Exercise]) -> Void)?

    private var selectedEquipment: Set<Equipment> = []
    private var selectedMuscleType: Set<MuscleGroup> = []

    private var searchText: String = ""

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Add Exercise"
        navigationController?.navigationBar.prefersLargeTitles = false

        saveButton.isEnabled = false

        setupUI()
        loadData()
        applyFilters()

    }
    private func setupUI(){
        addExerciseSearchBar.delegate = self

        addExerciseSearchBar.backgroundImage = UIImage()
        addExerciseSearchBar.backgroundColor = .clear

        if let searchField = addExerciseSearchBar.value(forKey: "searchField") as? UITextField {
            searchField.backgroundColor = .white
            searchField.layer.cornerRadius = 18
            searchField.layer.masksToBounds = true
            searchField.layer.borderWidth = 1
            searchField.layer.borderColor = UIColor.systemGray5.cgColor
        }

        equipmentsFilterButton.setTitle("All Equipment", for: .normal)
        muscleTypeFilterButton.setTitle("All Muscles", for: .normal)
        updateButtonAppearance()

        tableView.dataSource = self

        tableView.delegate = self
        tableView.allowsMultipleSelection = true
        tableView.estimatedRowHeight = 88
    }

    private func loadData(){

        exercises = ExerciseDataStore.shared.allExercises
    }

    @IBAction func showEquipmentSelectionButton(_ sender: UIButton) {
        performSegue(withIdentifier: "showEquipmentSelectionVC", sender: nil)
    }

    @IBAction func showMuscleSelectionButton(_ sender: UIButton) {
        performSegue(withIdentifier: "showMuscleSelectionVC", sender: nil)
    }

    private func applyFilters(){

        var result = exercises

        if !selectedEquipment.isEmpty && !selectedEquipment.contains(.allEquipment) {
                result = result.filter { exercise in
                    selectedEquipment.contains(exercise.equipment)
                }
            }

        if !selectedMuscleType.isEmpty && !selectedMuscleType.contains(.allMuscles){
            result=result.filter{
                exercise in selectedMuscleType.contains(exercise.muscleGroup)
            }
        }

        if !searchText.isEmpty{
            result=result.filter{
                exercise in
                exercise.name.lowercased().contains(searchText.lowercased()) ||
                exercise.muscleGroup.displayName.lowercased().contains(searchText.lowercased())
            }
        }

        filteredExercises = result
        tableView.reloadData()
        restoreSelectionState()
        updateButtonAppearance()
    }

    private func restoreSelectionState() {
        for (index, exercise) in filteredExercises.enumerated() {
            if selectedExerciseIDs.contains(exercise.id) {
                let indexPath = IndexPath(row: index, section: 0)
                tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)

                if let cell = tableView.cellForRow(at: indexPath) {
                    cell.accessoryType = .checkmark
                    cell.selectionStyle = .none
                }
            }
        }
    }

    private func updateButtonAppearance(){

        if selectedEquipment.isEmpty||selectedEquipment.contains(.allEquipment){
            equipmentsFilterButton.setTitle( "All Equipment", for: .normal)
            equipmentsFilterButton.backgroundColor = .systemGray5
            equipmentsFilterButton.setTitleColor(.label, for: .normal)
        }
        else if selectedEquipment.count==1 {

            equipmentsFilterButton.setTitle(selectedEquipment.first?.displayName ?? "Equipment",for : .normal)
            equipmentsFilterButton.backgroundColor = .systemBlue
            equipmentsFilterButton.setTitleColor(.white, for: .normal)
        }
        else{
            equipmentsFilterButton.setTitle("\(selectedEquipment.count) Equipments", for: .normal)
            equipmentsFilterButton.backgroundColor = .systemBlue
            equipmentsFilterButton.setTitleColor(.white, for: .normal)
        }
        if selectedMuscleType.isEmpty||selectedMuscleType.contains(.allMuscles){
            muscleTypeFilterButton.setTitle( "All Muscles", for: .normal)
            muscleTypeFilterButton.backgroundColor = .systemGray5
            muscleTypeFilterButton.setTitleColor(.label, for: .normal)
        }
        else if selectedMuscleType.count==1 {
            muscleTypeFilterButton.setTitle(selectedMuscleType.first?.displayName ?? " Muscle",for : .normal)
            muscleTypeFilterButton.backgroundColor = .systemBlue
            muscleTypeFilterButton.setTitleColor(.white, for: .normal)
        }
        else{
            muscleTypeFilterButton.setTitle("\(selectedMuscleType.count) Muscles", for: .normal)
            muscleTypeFilterButton.backgroundColor = .systemBlue
            muscleTypeFilterButton.setTitleColor(.white, for: .normal)
        }
    }

    private func updateSaveButtonState() {
        saveButton.isEnabled = !selectedExerciseIDs.isEmpty
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        if segue.identifier=="showEquipmentSelectionVC"{
            if let navController=segue.destination as? UINavigationController,
               let selectionVC=navController.topViewController as? EquipmentSelectionViewController {

                selectionVC.selectedEquipment = selectedEquipment

                selectionVC.onSave = { [weak self] newSelections in
                    self?.selectedEquipment = newSelections
                    self?.applyFilters()
                }
            }
        }

        if segue.identifier=="showMuscleSelectionVC"{
            if let navController=segue.destination as? UINavigationController,
               let selectionVC=navController.topViewController as? MuscleTypeSelectionViewController {
                selectionVC.selectedMuscles = selectedMuscleType
                selectionVC.onSave = { [weak self] newSelections in
                    self?.selectedMuscleType = newSelections
                    self?.applyFilters()
                }
            }
        }
    }

    @IBAction func saveButtonTapped(_ sender: UIBarButtonItem) {

        let selectedExercises = exercises.filter { exercise in
            selectedExerciseIDs.contains(exercise.id)
        }

        onExercisesSelected?(selectedExercises)

        navigationController?.popViewController(animated: true)

    }

}

extension AddExerciseViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredExercises.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        guard let cell = tableView.dequeueReusableCell(withIdentifier: "add_exercise_cell", for: indexPath) as? AddExerciseTableViewCell else {
            return UITableViewCell()
        }

        let exercise = filteredExercises[indexPath.row]

        cell.exerciseNameHeadline.text = exercise.name
        cell.muscleTypeSubheadline.text = exercise.muscleGroup.displayName

        if let imageName = exercise.image, !imageName.isEmpty {
            cell.addExerciseImageView.image = UIImage(named: imageName)
        } else {
            cell.addExerciseImageView.image = nil 
        }

        if selectedExerciseIDs.contains(exercise.id) {
                    cell.accessoryType = .checkmark
                    cell.selectionStyle = .none
                } else {
                    cell.accessoryType = .none
                    cell.selectionStyle = .default
                }

        return cell
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        60
    }
}

extension AddExerciseViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let exercise = filteredExercises[indexPath.row]

        selectedExerciseIDs.insert(exercise.id)

        if let cell = tableView.cellForRow(at: indexPath) { cell.accessoryType = .checkmark

            cell.selectionStyle = .none
        }

        updateSaveButtonState()
    }

    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        let exercise = filteredExercises[indexPath.row]

            selectedExerciseIDs.remove(exercise.id)

            if let cell = tableView.cellForRow(at: indexPath) {
                cell.accessoryType = .none
            }

        updateSaveButtonState()
    }
}
extension AddExerciseViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.searchText = searchText
        applyFilters()
    }
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        searchText = ""
        searchBar.resignFirstResponder()
        applyFilters()
    }
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}
