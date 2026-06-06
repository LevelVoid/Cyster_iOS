import UIKit

class PredefinedRoutinesViewController: UIViewController,UITableViewDelegate, UITableViewDataSource {
    var routine: Routine!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var routineNameLabel: UILabel!
    @IBOutlet weak var exercisesTableView: UITableView!
    @IBOutlet weak var saveButtonOutlet: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        saveButtonOutlet.tintColor = UIColor(hex: "#FE7A96")
        title = routine.name
        navigationController?.navigationBar.prefersLargeTitles = false
        descriptionLabel.text = routine.routineDescription
        exercisesTableView.delegate = self
        exercisesTableView.dataSource = self
        exercisesTableView.register(
                    UINib(nibName: "PredefinedExerciseTableViewCell", bundle: nil),
                    forCellReuseIdentifier: "predefined_exercise_cell"
                )
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return routine.exercises.count
        }

        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

            let cell = tableView.dequeueReusableCell(
                withIdentifier: "predefined_exercise_cell",
                for: indexPath
            ) as! PredefinedExerciseTableViewCell

            let item = routine.exercises[indexPath.row]

            cell.exerciseNameLabel.text = item.exercise.name

            if item.exercise.isTimeBased {
                let duration = item.durationSeconds ?? 0
                let mins = duration / 60
                let secs = duration % 60
                if mins > 0 && secs > 0 {
                    cell.detailLabel.text = "\(mins)m \(secs)s"
                } else if secs > 0 {
                    cell.detailLabel.text = "\(secs)s"
                } else {
                    cell.detailLabel.text = "\(mins) min"
                }
            } else {
                cell.detailLabel.text = "\(item.numberOfSets) sets • \(item.reps) reps"
            }

            cell.thumbnailImage.image = UIImage(named: item.exercise.image ?? "placeholder")

            return cell
        }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        60
    }

        @IBAction func saveRoutineTapped(_ sender: UIButton) {
            UserRoutineDataStore.shared.save(routine)

            navigationController?.popViewController(animated: true)
        }
    }

