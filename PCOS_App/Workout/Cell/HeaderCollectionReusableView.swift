import UIKit

class HeaderCollectionReusableView: UICollectionReusableView {

    @IBOutlet weak var headerLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()

    }

    func configureHeader(with title: String) {
        headerLabel.text = title
    }
}
