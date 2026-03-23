import UIKit

class NoFoodCollectionViewCell: UICollectionViewCell {

    static let identifier = "NoFoodCollectionViewCell"
    static func nib() -> UINib {
        return UINib(nibName: identifier, bundle: nil)
    }

    @IBOutlet weak var quoteLabel: UILabel!

    private let quotes = [
        "Nourish your body — log a wholesome meal to get started.",
        "Healthy eating begins with one mindful meal. Start today.",
        "Your body works hard for you. Feed it something good today.",
        "A balanced meal is the best thing you can do for yourself right now.",
        "Small steps lead to big change. Log your first meal today."
    ]

    override func awakeFromNib() {
        super.awakeFromNib()
        quoteLabel.text = quotes.randomElement() ?? quotes[0]
    }

    func refreshQuote() {
        quoteLabel.text = quotes.randomElement() ?? quotes[0]
    }
}
