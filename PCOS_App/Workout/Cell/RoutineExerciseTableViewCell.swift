import UIKit
class RoutineExerciseTableViewCell: UITableViewCell {

    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var exerciseNameLabel: UILabel!
    @IBOutlet weak var muscleTypeLabel: UILabel!
    @IBOutlet weak var exerciseImageView: UIImageView!

    @IBOutlet weak var setsTextField: UITextField!
    @IBOutlet weak var repsTextField: UITextField!
    @IBOutlet weak var weightTextField: UITextField!
    @IBOutlet weak var restTimerLabel: UILabel!
    @IBOutlet weak var durationTextField: UITextField! 

    @IBOutlet weak var strengthStackView: UIStackView!
    @IBOutlet weak var cardioStackView: UIStackView!

    var onValueChanged: (() -> Void)?

    private var routineExercise: RoutineExercise?
    var onInfoTapped: (() -> Void)?

    @IBAction func infoButtonTapped(_ sender: UIButton) {
        onInfoTapped?()
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        containerView.layer.cornerRadius = 16

        selectionStyle = .none

        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOpacity = 0.08   
        containerView.layer.shadowRadius = 10
        containerView.layer.shadowOffset = CGSize(width: 0, height: 4)

        exerciseImageView.clipsToBounds = true
        exerciseImageView.layer.cornerRadius = 8

        exerciseNameLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        exerciseNameLabel.textColor = .label

        muscleTypeLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        muscleTypeLabel.textColor = .secondaryLabel

        setsTextField.delegate = self
        repsTextField.delegate = self
        weightTextField.delegate = self
        durationTextField.delegate = self

        setsTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        repsTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        weightTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        durationTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

    }

    override func prepareForReuse() {
        super.prepareForReuse()
        exerciseImageView.image = nil
        exerciseNameLabel.text = nil
        muscleTypeLabel.text = nil
    }

    func configure(with model: RoutineExercise) {

        self.routineExercise = model

        exerciseNameLabel.text = model.exercise.name
        muscleTypeLabel.text = model.exercise.muscleGroup.displayName

        if let img = model.exercise.image {
            exerciseImageView.image = UIImage(named: img)
        } else {
            exerciseImageView.image = UIImage(systemName: "figure.strengthtraining.traditional")
        }

        if model.exercise.isTimeBased {
            strengthStackView.isHidden = true
            cardioStackView.isHidden = false

            let defaultDuration = model.exercise.isYoga ? 60 : 600
            let durationInSeconds = model.durationSeconds ?? defaultDuration
            let minutes = max(1, durationInSeconds / 60)
            durationTextField.text = "\(minutes)"

        } else {
            strengthStackView.isHidden = false
            cardioStackView.isHidden = true

            setsTextField.text = "\(model.numberOfSets)"
            repsTextField.text = "\(model.reps)"
            weightTextField.text = "\(model.weightKg)"

        }
    }
    @objc private func textFieldDidChange(_ textField: UITextField) {
            guard var exercise = routineExercise else { return }

            if textField == setsTextField {
                if let value = Int(textField.text ?? ""), value > 0 {
                    exercise.numberOfSets = value
                }
            } else if textField == repsTextField {
                if let value = Int(textField.text ?? ""), value > 0 {
                    exercise.reps = value
                }
            } else if textField == weightTextField {
                if let value = Int(textField.text ?? ""), value >= 0 {
                    exercise.weightKg = value
                }
            } else if textField == durationTextField {

                if let minutes = Int(textField.text ?? ""), minutes > 0 {
                    exercise.durationSeconds = minutes * 60
                }
            }

            self.routineExercise = exercise

            onValueChanged?()
        }

        func getRoutineExercise() -> RoutineExercise? {
            return routineExercise
        }
    }

    extension RoutineExerciseTableViewCell: UITextFieldDelegate {

        func textFieldDidEndEditing(_ textField: UITextField) {

            textFieldDidChange(textField)
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            textField.resignFirstResponder()
            return true
        }

        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            let allowedCharacters = CharacterSet.decimalDigits
            let characterSet = CharacterSet(charactersIn: string)
            return allowedCharacters.isSuperset(of: characterSet)
        }

    }
