import UIKit

class FoodSuggestionsCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var mainContent: UIView!

    static let identifier = "FoodSuggestionsCollectionViewCell"
    static func nib() -> UINib {
        return UINib(nibName: identifier, bundle: nil)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }
    
    private func setupUI() {
        // iOS native card styling without shadows
        mainContent.layer.cornerRadius = 20
        mainContent.clipsToBounds = true
        mainContent.backgroundColor = .white
        
        mainContent.layer.shadowColor = UIColor.clear.cgColor
        mainContent.layer.shadowOpacity = 0
        mainContent.layer.shadowOffset = .zero
        mainContent.layer.shadowRadius = 0
        
        // Ensure no shadows on self or contentView just in case
        self.layer.shadowColor = UIColor.clear.cgColor
        self.layer.shadowOpacity = 0
        self.contentView.layer.shadowColor = UIColor.clear.cgColor
        self.contentView.layer.shadowOpacity = 0
        
        self.clipsToBounds = false
        self.contentView.clipsToBounds = true
        
        // Optionally style inner colored stack views for native look
        if let stackView = mainContent.subviews.compactMap({ $0 as? UIStackView }).first {
            stackView.layer.cornerRadius = 12
            stackView.clipsToBounds = true
            
            for view in stackView.arrangedSubviews {
                view.layer.cornerRadius = 0 // Keeping it flat if desired by user's storyboard, but just making sure it stays inside
            }
        }
    }
}
