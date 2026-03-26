import UIKit

class FoodSuggestionsCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var thirdView: UIView!
    @IBOutlet weak var firstView: UIView!
    @IBOutlet weak var secondView: UIView!
    @IBOutlet weak var mainContent: UIView!
    @IBOutlet weak var DescriptionFocus: UILabel!
    
    @IBOutlet weak var MealName1: UILabel!
    @IBOutlet weak var mealGram1: UILabel!
    @IBOutlet weak var ImpactTag_1: UILabel!
    
    
    @IBOutlet weak var MealName2: UILabel!
    @IBOutlet weak var mealGram2: UILabel!
    @IBOutlet weak var ImpactTag_2: UILabel!
    
    
    @IBOutlet weak var MealName3: UILabel!
    @IBOutlet weak var mealGram3: UILabel!
    @IBOutlet weak var ImpactTag_3: UILabel!
    
    
    static let identifier = "FoodSuggestionsCollectionViewCell"
    static func nib() -> UINib {
        return UINib(nibName: identifier, bundle: nil)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Enable multi-line for labels to support dynamic height
        DescriptionFocus.numberOfLines = 0
        MealName1.numberOfLines = 0
        MealName2.numberOfLines = 0
        MealName3.numberOfLines = 0
        
        // Also ensure impact tags can wrap if they are long
        ImpactTag_1.numberOfLines = 0
        ImpactTag_2.numberOfLines = 0
        ImpactTag_3.numberOfLines = 0
        
        // Fix missing bottom constraints programmatically so StackView can compute intrinsic height
        firstView.bottomAnchor.constraint(greaterThanOrEqualTo: mealGram1.bottomAnchor, constant: 16).isActive = true
        secondView.bottomAnchor.constraint(greaterThanOrEqualTo: mealGram2.bottomAnchor, constant: 16).isActive = true
        thirdView.bottomAnchor.constraint(greaterThanOrEqualTo: mealGram3.bottomAnchor, constant: 16).isActive = true
        
        // Set minimum height for each food slot to accommodate image/content gracefully
        firstView.heightAnchor.constraint(greaterThanOrEqualToConstant: 80).isActive = true
        secondView.heightAnchor.constraint(greaterThanOrEqualToConstant: 80).isActive = true
        thirdView.heightAnchor.constraint(greaterThanOrEqualToConstant: 80).isActive = true
        
        // Ensure mainContent is constrained to contentView for UICollectionViewCell auto-sizing
        mainContent.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            mainContent.topAnchor.constraint(equalTo: contentView.topAnchor),
            mainContent.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            mainContent.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            mainContent.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }

    // MARK: - States
    func showLoadingState() {
        DescriptionFocus.text = "Fetching personalized recommendations..."
        //DescriptionFocus.textColor = .tertiaryLabel
        [firstView, secondView, thirdView].forEach { $0?.isHidden = true }
    }

    func showErrorState(message: String) {
        DescriptionFocus.text = message
        [firstView, secondView, thirdView].forEach { $0?.isHidden = true }
    }

    // MARK: - Configure with AI Output
    func configure(with output: MealRecommendationOutput) {
        firstView.layer.cornerRadius = 10
        secondView.layer.cornerRadius = 10
        thirdView.layer.cornerRadius = 10
        
        DescriptionFocus.text = output.observationLine
        let foods = output.foods
        
        // Slot 1
        if foods.count > 0 {
            firstView.isHidden = false
            MealName1.text = foods[0].name
            mealGram1.text = foods[0].primaryMacro
            ImpactTag_1.text = foods[0].impactTag
        } else {
            firstView.isHidden = true
        }

        // Slot 2
        if foods.count > 1 {
            secondView.isHidden = false
            MealName2.text = foods[1].name
            mealGram2.text = foods[1].primaryMacro
            ImpactTag_2.text = foods[1].impactTag
        } else {
            secondView.isHidden = true
        }

        // Slot 3
        if foods.count > 2 {
            thirdView.isHidden = false
            MealName3.text = foods[2].name
            mealGram3.text = foods[2].primaryMacro
            ImpactTag_3.text = foods[2].impactTag
        } else {
            thirdView.isHidden = true
        }
    }
}
