import UIKit

class AddExerciseTableViewCell: UITableViewCell {

    @IBOutlet weak var muscleTypeSubheadline: UILabel!
    @IBOutlet weak var exerciseNameHeadline: UILabel!
    @IBOutlet weak var addExerciseImageView: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()

        contentView.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
        preservesSuperviewLayoutMargins = false
        separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0)

    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}
