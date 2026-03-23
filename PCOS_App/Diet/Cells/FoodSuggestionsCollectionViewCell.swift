import UIKit

class FoodSuggestionsCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var mainContent: UIView!

    static let identifier = "FoodSuggestionsCollectionViewCell"
    static func nib() -> UINib {
        return UINib(nibName: identifier, bundle: nil)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
    }
}
