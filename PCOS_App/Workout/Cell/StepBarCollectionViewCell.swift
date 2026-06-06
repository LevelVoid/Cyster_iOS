import UIKit

class StepBarCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var barView: UIView!
    @IBOutlet weak var heightConstraint: NSLayoutConstraint!
    override func awakeFromNib() {
        super.awakeFromNib()
        barView.layer.cornerRadius = 6
        barView.clipsToBounds = true
    }
    func configure(value: Int, maxValue: Int, color: UIColor) {
        let maxHeight: CGFloat = 180  
        let safeMax = max(maxValue, 1)
        let ratio = CGFloat(value) / CGFloat(safeMax)

        heightConstraint.constant = maxHeight * ratio
        barView.backgroundColor = color
        barView.alpha = value == 0 ? 0.3 : 1.0

        UIView.animate(withDuration: 0.3) {
            self.layoutIfNeeded()
        }
    }

    }

