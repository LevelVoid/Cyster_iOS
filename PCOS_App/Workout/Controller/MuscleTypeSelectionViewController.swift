import UIKit

class MuscleTypeSelectionViewController: UIViewController {

    @IBOutlet weak var targettedMuscleTableView: UITableView!

    private let allMuscles=MuscleGroup.allCases
    var selectedMuscles:Set<MuscleGroup> = []
    var onSave:((Set<MuscleGroup>)->Void)?

    override func viewDidLoad() {
        super.viewDidLoad()

                if selectedMuscles.isEmpty {
                    selectedMuscles.insert(.allMuscles)
                }
        setupUI()

    }
    private func setupUI(){
        title = "Select Muscles"
        targettedMuscleTableView.delegate=self
        targettedMuscleTableView.dataSource=self

        targettedMuscleTableView.allowsMultipleSelection = true
    }

    @IBAction func muscleCloseButtonTapped(_ sender: UIBarButtonItem) {
        dismiss(animated: true)
    }

    @IBAction func muscleSaveButtonTapped(_ sender: UIBarButtonItem) {
        onSave?(selectedMuscles)
        dismiss(animated: true)
    }
}
extension MuscleTypeSelectionViewController:UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        allMuscles.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: "muscle_cell",
            for: indexPath
        ) as? MuscleTypeSelectionTableViewCell else {
            return UITableViewCell()
        }

        let muscle=allMuscles[indexPath.row]

        cell.muscleTypeLabel.text = muscle.displayName

        if selectedMuscles.contains(muscle){
            cell.accessoryType = .checkmark
        }
        else {
            cell.accessoryType = .none
        }

        let imageName = muscle.displayImage
        if !imageName.isEmpty {
            cell.muscleTypeImageView.image = UIImage(named: imageName)
        } else {
            cell.muscleTypeImageView.image = nil 
        }

        return cell
    }
}
extension MuscleTypeSelectionViewController:UITableViewDelegate{
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let muscle = allMuscles[indexPath.row]

        if muscle == .allMuscles {

            if selectedMuscles.contains(.allMuscles) {
                selectedMuscles.remove(.allMuscles)
            } else {

                selectedMuscles.removeAll()
                selectedMuscles.insert(.allMuscles)
            }

            tableView.reloadData()
        } else {

            if selectedMuscles.contains(.allMuscles) {
                selectedMuscles.remove(.allMuscles)

                if let allIndex = allMuscles.firstIndex(of: .allMuscles) {
                    tableView.reloadRows(at: [IndexPath(row: allIndex, section: 0)], with: .automatic)
                }
            }

            if selectedMuscles.contains(muscle){
                selectedMuscles.remove(muscle)
            }
            else {
                selectedMuscles.insert(muscle)
            }

            tableView.reloadRows(at: [indexPath], with: .automatic)
        }
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        60
    }
}

