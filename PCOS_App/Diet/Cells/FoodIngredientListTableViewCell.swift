import UIKit

class FoodIngredientListTableViewCell: UITableViewCell {

    @IBOutlet weak var IngredientNameLabel: UILabel!
    @IBOutlet weak var IngredientCalorieLabel: UILabel!

    @IBOutlet weak var IngredientWeightLabel: UILabel!

    static var identifier = "FoodIngredientListTableViewCell"
    static func nib() -> UINib {
        return UINib(nibName: identifier, bundle: nil)
    }
    override func awakeFromNib() {
        super.awakeFromNib()

    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

    }

    func configureCell(with ingredient: Ingredient){
        IngredientNameLabel.text = ingredient.name

        let cals = ingredient.calories ?? 0
        IngredientCalorieLabel.text = "\(Int(cals)) kcal"

        IngredientWeightLabel.isHidden = true
    }

}
