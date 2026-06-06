import Foundation
import UIKit

class HealthDetailsTableViewController: UITableViewController, UITextFieldDelegate {

    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var NameField: UITextField!
    @IBOutlet weak var dob: UIDatePicker!

    @IBOutlet weak var weightField: UITextField!
    @IBOutlet weak var heightField: UITextField!

    @IBOutlet weak var dietTypeButton: UIButton!
    @IBOutlet weak var workoutTypeButton: UIButton!

    @IBOutlet weak var phenotypeButton: UIButton!

     var allTextFields: [UITextField] = []
     var allButtons: [UIButton] = []

     var profileData: ProfileModel {
         get {

             if let user = ProfileService.shared.getProfile() {
                 return ProfileModel(
                     name: user.name ?? "",
                     dob: user.dateOfBirth ?? Date(),
                     height: Int(user.heightCm),
                     weight: Int(user.weightKg),
                     dietType: user.dietPattern ?? "Not sure yet",
                     workoutType: user.activityLevel ?? "Mostly sedentary",
                     pcosPhenotype: user.pcosPhenotype ?? "I Don't Know"
                 )
             }
             return ProfileModel(
                 name: "",
                 dob: Date(),
                 height: 0,
                 weight: 0,
                 dietType: "Not sure yet",
                 workoutType: "Mostly sedentary",
                 pcosPhenotype: "I Don't Know"
             )
         }
         set {
             ProfileService.shared.setProfile(to: newValue)
         }
     }

     override func viewDidLoad() {
         super.viewDidLoad()

         weightField.delegate = self
         heightField.delegate = self

         weightField.keyboardType = .decimalPad
         heightField.keyboardType = .decimalPad

         profileImage.addFullRoundedCorner()

         self.navigationItem.rightBarButtonItem = self.editButtonItem

         allTextFields = [
             NameField, heightField, weightField,
         ]
         allButtons = [dietTypeButton, workoutTypeButton, phenotypeButton]

         updateTextFieldsState(isEditing: false)

         setupFields()
     }

     override func viewWillAppear(_ animated: Bool) {
         super.viewWillAppear(animated)
         setupFields() 
     }

     private func setupFields() {
         let profile = profileData 

         NameField.text = profile.name

         if profile.height > 0 {
             heightField.text = "\(profile.height)"
         } else {
             heightField.text = "Not Set"
         }

         if profile.weight > 0 {
             weightField.text = "\(profile.weight)"
         } else {
             weightField.text = "Not Set"
         }

         dob.date = profile.dob

         setupDietTypeButton()
         setupWorkoutTypeButton()
         setupPhenotypeButton()
     }

        @IBAction func dietTypeTapped(_ sender: UIButton) {

        }

        @IBAction func workoutTypeTapped(_ sender: UIButton) {

        }

        @IBAction func phenotypeTapped(_ sender: UIButton) {

        }

    func setupDietTypeButton() {
           let currentProfile = profileData

           let selectionClosure = { (action: UIAction) in
               print("Diet Type Selected: \(action.title)")
           }

           let allDietTypes = [
               "Balanced Diet",
               "Frequent Sugar",
               "Irregular Meals",
               "Not Sure Yet"
           ]

           let actions: [UIAction] = allDietTypes.map { typeTitle in
               let currentState: UIMenuElement.State =
                   (typeTitle == currentProfile.dietType) ? .on : .off

               let action = UIAction(
                   title: typeTitle,
                   state: currentState,
                   handler: selectionClosure
               )
               return action
           }

           let menu = UIMenu(children: actions)
           dietTypeButton.menu = menu
           dietTypeButton.showsMenuAsPrimaryAction = true
           dietTypeButton.changesSelectionAsPrimaryAction = true

           dietTypeButton.setTitle(currentProfile.dietType, for: .normal)
       }

       func setupWorkoutTypeButton() {
           let currentProfile = profileData

           let selectionClosure = { (action: UIAction) in
               print("Workout Type Selected: \(action.title)")
           }

           let allWorkoutTypes = [
               "Sedentary Type",
               "Light Movements",
               "Regular Movements",
               "Very active on most days"
           ]

           let actions: [UIAction] = allWorkoutTypes.map { typeTitle in
               let currentState: UIMenuElement.State =
                   (typeTitle == currentProfile.workoutType) ? .on : .off

               let action = UIAction(
                   title: typeTitle,
                   state: currentState,
                   handler: selectionClosure
               )
               return action
           }

           let menu = UIMenu(children: actions)
           workoutTypeButton.menu = menu
           workoutTypeButton.showsMenuAsPrimaryAction = true
           workoutTypeButton.changesSelectionAsPrimaryAction = true

           workoutTypeButton.setTitle(currentProfile.workoutType, for: .normal)
       }

       func setupPhenotypeButton() {
           let currentProfile = profileData

           let selectionClosure = { (action: UIAction) in
               print("PCOS Phenotype Selected: \(action.title)")
           }

           let allPhenotypes = [
               "Type A",
               "Type B",
               "Type C",
               "Type D",
               "I Don't Know"
           ]

           let actions: [UIAction] = allPhenotypes.map { typeTitle in
               let currentState: UIMenuElement.State =
                   (typeTitle == currentProfile.pcosPhenotype) ? .on : .off

               let action = UIAction(
                   title: typeTitle,
                   state: currentState,
                   handler: selectionClosure
               )
               return action
           }

           let menu = UIMenu(children: actions)
           phenotypeButton.menu = menu
           phenotypeButton.showsMenuAsPrimaryAction = true
           phenotypeButton.changesSelectionAsPrimaryAction = true

           phenotypeButton.setTitle(currentProfile.pcosPhenotype, for: .normal)
       }

       override func setEditing(_ editing: Bool, animated: Bool) {

           if editing {
               if heightField.text == "Not Set" {
                   heightField.text = ""
               }
               if weightField.text == "Not Set" {
                   weightField.text = ""
               }
           }

           if !editing {
               let name = NameField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

               if name.isEmpty {
                   showAlert(message: "Name cannot be empty.")
                   super.setEditing(true, animated: false)
                   return
               }

               if heightField.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true {
                   heightField.text = "Not Set"
               }

               if weightField.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true {
                   weightField.text = "Not Set"
               }

               saveData()
           }

           super.setEditing(editing, animated: animated)
           updateTextFieldsState(isEditing: editing)
       }

       func updateTextFieldsState(isEditing: Bool) {

           for field in allTextFields {
               field.isUserInteractionEnabled = isEditing
               field.borderStyle = isEditing ? .roundedRect : .none
               field.textColor = isEditing ? .systemBlue : .label
           }

           for button in allButtons {
               button.isUserInteractionEnabled = isEditing
               button.tintColor = isEditing ? .systemBlue : .label
           }

           dob.isUserInteractionEnabled = isEditing
           dob.alpha = 1.0

           if isEditing {
               NameField.becomeFirstResponder()
           } else {
               view.endEditing(true)
           }
       }

       func saveData() {
           print("Saving Data...")
           let profile = ProfileModel(
               name: NameField.text ?? "",
               dob: dob.date,
               height: Int(heightField.text ?? "") ?? 0,
               weight: Int(weightField.text ?? "") ?? 0,
               dietType: dietTypeButton.titleLabel?.text ?? "",
               workoutType: workoutTypeButton.titleLabel?.text ?? "",
               pcosPhenotype: phenotypeButton.titleLabel?.text ?? ""
           )

           ProfileService.shared.setProfile(to: profile)
       }

       override func tableView(
           _ tableView: UITableView,
           editingStyleForRowAt indexPath: IndexPath
       ) -> UITableViewCell.EditingStyle {
           return .none
       }

       override func tableView(
           _ tableView: UITableView,
           shouldIndentWhileEditingRowAt indexPath: IndexPath
       ) -> Bool {
           return false
       }

       func textField(
           _ textField: UITextField,
           shouldChangeCharactersIn range: NSRange,
           replacementString string: String
       ) -> Bool {

           if textField == weightField || textField == heightField {
               if string.isEmpty { return true }

               let allowedCharacters = CharacterSet(charactersIn: "0123456789.")
               let characterSet = CharacterSet(charactersIn: string)

               let isNumber = allowedCharacters.isSuperset(of: characterSet)

               if isNumber {
                   let currentText = textField.text ?? ""
                   if string == "." && currentText.contains(".") {
                       return false
                   }
                   return true
               } else {
                   return false
               }
           }

           return true
       }

       override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
           let headerView = UIView()
           headerView.backgroundColor = .clear

           let titleLabel = UILabel()
           titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
           titleLabel.textColor = .label
           titleLabel.translatesAutoresizingMaskIntoConstraints = false

           switch section {
           case 0:
               titleLabel.text = "Personal Information"
           case 1:
               titleLabel.text = "Physical Measurements"
           case 2:
               titleLabel.text = "Lifestyle"
           default:
               return nil
           }

           headerView.addSubview(titleLabel)

           NSLayoutConstraint.activate([
               titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20),
               titleLabel.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -12),
               titleLabel.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 15)
           ])

           return headerView
       }

       override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
           return 60
       }

       override func viewDidLayoutSubviews() {
           super.viewDidLayoutSubviews()

           removeBorder(from: NameField)
           removeBorder(from: heightField)
           removeBorder(from: weightField)
       }

       func removeBorder(from textField: UITextField) {
           textField.borderStyle = .none
           textField.backgroundColor = .clear
           textField.layer.borderWidth = 0
           textField.layer.borderColor = UIColor.clear.cgColor

           if #available(iOS 15.0, *) {
               textField.focusEffect = nil
           }
       }

       func showAlert(message: String) {
           let alert = UIAlertController(title: "Missing Information", message: message, preferredStyle: .alert)
           alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
           present(alert, animated: true, completion: nil)
       }
   }
