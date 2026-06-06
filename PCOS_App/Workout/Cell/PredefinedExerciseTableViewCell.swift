import UIKit

class PredefinedExerciseTableViewCell: UITableViewCell {
        @IBOutlet weak var thumbnailImage: UIImageView!
        @IBOutlet weak var exerciseNameLabel: UILabel!
        @IBOutlet weak var detailLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()

    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

    }

}
