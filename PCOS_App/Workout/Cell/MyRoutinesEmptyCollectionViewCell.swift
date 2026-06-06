import UIKit

class MyRoutinesEmptyCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var messageLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()

        containerView.layer.cornerRadius = 20

        messageLabel.text = "Get started by creating a routine"
        messageLabel.textColor = .secondaryLabel
        messageLabel.textAlignment = .center

    }
}
