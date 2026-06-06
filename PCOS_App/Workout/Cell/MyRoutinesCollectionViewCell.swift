import UIKit

class MyRoutinesCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var routineNameOutlet: UILabel!

    @IBOutlet weak var MyRoutinesImageOutlet: UIImageView!
    @IBOutlet weak var timeTagContainer: UIView!

    @IBOutlet weak var EstimatedTimeLabelOutlet: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()

        containerView.layer.cornerRadius = 20
        containerView.layer.masksToBounds = true

        timeTagContainer.layer.cornerRadius = timeTagContainer.frame.height/2
    }
    func configureCell(with routine: Routine) {
            routineNameOutlet.text = routine.name
        if let imageName = routine.thumbnailImageName {
            MyRoutinesImageOutlet.image = UIImage(named: imageName)

            EstimatedTimeLabelOutlet.text = routine.formattedDuration
        }

        }

}
