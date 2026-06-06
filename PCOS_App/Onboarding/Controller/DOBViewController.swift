import UIKit

class DOBViewController: UIViewController {

    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var nextButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        nextButton.tintColor = UIColor(hex: "FE7A96")
        setupDatePicker()
    }

    private func setupDatePicker() {

        datePicker.preferredDatePickerStyle = .wheels
        datePicker.datePickerMode = .date

        datePicker.maximumDate = Date()

        let calendar = Calendar.current
        if let minDate = calendar.date(byAdding: .year, value: -100, to: Date()) {
            datePicker.minimumDate = minDate
        }

        if let defaultDate = calendar.date(byAdding: .year, value: -25, to: Date()) {
            datePicker.date = defaultDate
        }
    }

    @IBAction func nextButtonTapped(_ sender: UIButton) {
        let selectedDate = datePicker.date

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        let dateString = formatter.string(from: selectedDate)

        print("Date of Birth: \(dateString)")

        UserDefaults.standard.set(selectedDate, forKey: "userDOB")

        let age = Calendar.current.dateComponents([.year], from: selectedDate, to: Date()).year ?? 0
        print("Age: \(age)")

       performSegue(withIdentifier: "showHeight", sender: nil)
    }
}
