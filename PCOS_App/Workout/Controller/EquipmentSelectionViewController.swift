import UIKit

class EquipmentSelectionViewController: UIViewController {

    @IBOutlet weak var equipmentTableView: UITableView!

    private let allEquipment = Equipment.allCases

    var selectedEquipment: Set<Equipment> = []
    var onSave: ((Set<Equipment>) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()

                if selectedEquipment.isEmpty {
                    selectedEquipment.insert(.allEquipment)
                }

        setupUI()

    }
    private func setupUI(){
        title = "Select Equipment"
        equipmentTableView.delegate = self
        equipmentTableView.dataSource = self
        equipmentTableView.allowsMultipleSelection = true

    }

    @IBAction func equipmentCloseButtonTapped(_ sender: UIBarButtonItem) {
        dismiss(animated: true)
    }

    @IBAction func equipmentSaveButtonTapped(_ sender: UIBarButtonItem) {
        onSave?(selectedEquipment)
        dismiss(animated: true)
    }
}
extension EquipmentSelectionViewController:UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        allEquipment.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "equipment_cell", for: indexPath) as? EquipmentSelectionTableViewCell else {
            return UITableViewCell()
        }

        let equipment = allEquipment[indexPath.row]

        cell.equipmentNameLabel.text = equipment.displayName
        if selectedEquipment.contains(equipment){
            cell.accessoryType = .checkmark
        }
        else {
            cell.accessoryType = .none
        }

        let imageName = equipment.displayImage
        if !imageName.isEmpty {
            cell.equipmentImageView.image = UIImage(named: imageName)
        } else {
            cell.equipmentImageView.image = nil 
        }

        return cell
    }
}
extension EquipmentSelectionViewController:UITableViewDelegate{
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            tableView.deselectRow(at: indexPath, animated: true)
            let equipment = allEquipment[indexPath.row]

            if equipment == .allEquipment {

                if selectedEquipment.contains(.allEquipment) {
                    selectedEquipment.remove(.allEquipment)
                } else {

                    selectedEquipment.removeAll()
                    selectedEquipment.insert(.allEquipment)
                }

                tableView.reloadData()
            } else {

                if selectedEquipment.contains(.allEquipment) {
                    selectedEquipment.remove(.allEquipment)

                    if let allIndex = allEquipment.firstIndex(of: .allEquipment) {
                        tableView.reloadRows(at: [IndexPath(row: allIndex, section: 0)], with: .automatic)
                    }
                }

                if selectedEquipment.contains(equipment){
                    selectedEquipment.remove(equipment)
                }
                else {
                    selectedEquipment.insert(equipment)
                }

                tableView.reloadRows(at: [indexPath], with: .automatic)
            }
        }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
}
