import UIKit

class FoodLogIngredientViewController: UIViewController {

    @IBOutlet weak var servingStepper: UIStepper!
    @IBOutlet weak var servingNumberLabel: UILabel!
    @IBOutlet weak var foodweightView: UIView!
    @IBOutlet weak var FoodWeightLabel: UILabel!
    @IBOutlet weak var horizontalStackView: UIStackView!

    @IBOutlet weak var tableView: UITableView!

        private var headerView: FoodLogIngredientHeader!
        let defaultIngredient = FoodLogDataStore.ingredient

        var food: Food!
        private var baseFood: Food!
        private var servingMultiplier: Double = 1.0

        override func viewDidLoad() {
            super.viewDidLoad()

            print("DEBUG: viewDidLoad started")
            tableView.dataSource = self
            tableView.delegate = self
            tableView.register(FoodIngredientListTableViewCell.nib(), forCellReuseIdentifier: FoodIngredientListTableViewCell.identifier)

            guard food != nil else {
                print("Error: No food data provided")
                navigationController?.popViewController(animated: true)
                return
            }

            print("DEBUG: Food data exists - \(food.name)")

            title = food?.name ?? "Food Details"

            navigationController?.navigationBar.prefersLargeTitles = false
            navigationItem.largeTitleDisplayMode = .never

            if let wt = food.weight, food.servingSize > 0 {
                servingMultiplier = wt / food.servingSize
            } else {
                servingMultiplier = 1.0
            }

            baseFood = food
            if servingMultiplier > 0 && servingMultiplier != 1.0 {
                baseFood.weight = food.servingSize
                baseFood.proteinContent = food.proteinContent / servingMultiplier
                baseFood.carbsContent = food.carbsContent / servingMultiplier
                baseFood.fatsContent = food.fatsContent / servingMultiplier
                if let cc = food.customCalories { baseFood.customCalories = cc / servingMultiplier }
                if let ing = food.ingredients {
                    baseFood.ingredients = ing.map { i in
                        var newI = i
                        newI.quantity = i.quantity / servingMultiplier
                        return newI
                    }
                }
            }

            setupHeader()
            setupStepper()
            setupServingLabel()
            setupWeightLabel()
            updateServingDisplay()

            print("DEBUG: viewDidLoad completed successfully")
        }

        private func setupHeader() {

            guard let food = food else {
                print("No food data available")
                return
            }

            guard let containerView = foodweightView else {
                return
            }

            containerView.subviews.forEach { $0.removeFromSuperview() }

            containerView.backgroundColor = .clear
            containerView.layer.cornerRadius = 16
            containerView.clipsToBounds = true

            headerView = FoodLogIngredientHeader.loadFromNib()

            containerView.addSubview(headerView)

            headerView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                headerView.topAnchor.constraint(equalTo: containerView.topAnchor),
                headerView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                headerView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
                headerView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
            ])

            headerView.configure(with: food)

            print("DEBUG: setupHeader - Complete")
        }

        private func setupStepper() {
            guard let stepper = servingStepper else {
                print("Error: servingStepper outlet is not connected!")
                return
            }

            stepper.minimumValue = 0.5
            stepper.maximumValue = 10.0
            stepper.stepValue = 0.5

            stepper.value = servingMultiplier

            stepper.tintColor = .label

            stepper.layer.cornerRadius = 10
            stepper.clipsToBounds = true
        }

        private func setupServingLabel() {
            guard let label = servingNumberLabel else { return }

            label.font = .systemFont(ofSize: 18, weight: .medium)
            label.textColor = .label
            label.adjustsFontSizeToFitWidth = true
            label.minimumScaleFactor = 0.7
        }

        private func setupWeightLabel() {
            guard let label = FoodWeightLabel else {
                print("Error: FoodWeightLabel outlet is not connected!")
                return
            }

            label.backgroundColor = .systemGray5
            label.layer.cornerRadius = 10
            label.clipsToBounds = true
            label.textAlignment = .center
            label.numberOfLines = 1
            label.adjustsFontSizeToFitWidth = true
            label.minimumScaleFactor = 0.7
            label.font = .systemFont(ofSize: 13, weight: .medium)
            label.textColor = .label

            label.layer.borderWidth = 1
            label.layer.borderColor = UIColor.systemGray3.cgColor

            print("DEBUG: FoodWeightLabel configured")
        }

        @IBAction func servingStepperChanged(_ sender: UIStepper) {
            servingMultiplier = sender.value
            updateServingDisplay()
            updateMacros()
            print(servingMultiplier)
        }

    @IBAction func saveButton(_ sender: Any) {
        guard var updatedFood = baseFood else { return }

        updatedFood.proteinContent = baseFood.proteinContent * servingMultiplier
        updatedFood.carbsContent = baseFood.carbsContent * servingMultiplier
        updatedFood.fatsContent = baseFood.fatsContent * servingMultiplier

        updatedFood.servingSize = baseFood.servingSize
        updatedFood.weight = baseFood.servingSize * servingMultiplier

        if let customCalories = baseFood.customCalories {
            updatedFood.customCalories = customCalories * servingMultiplier
        }
        if let ingredients = baseFood.ingredients {
            updatedFood.ingredients = ingredients.map { ingredient in
                var newIngredient = ingredient
                newIngredient.quantity = ingredient.quantity * servingMultiplier
                return newIngredient
            }
        }

        FoodLogDataStore.updateFood(updatedFood)
        navigationController?.popViewController(animated: true)
    }

        private func updateServingDisplay() {

            let servingText: String
            if servingMultiplier == 1.0 {
                servingText = "1 serving"
            } else if servingMultiplier.truncatingRemainder(dividingBy: 1) == 0 {
                servingText = "\(Int(servingMultiplier)) servings"
            } else {
                servingText = String(format: "%.1f servings", servingMultiplier)
            }

            servingNumberLabel?.text = servingText

            guard let baseFood = baseFood else { return }

            let scaledWeight: Double
            if baseFood.servingSize > 0 {
                scaledWeight = baseFood.servingSize * servingMultiplier
            } else {
                let ingTotal = (baseFood.ingredients ?? []).reduce(0.0) { $0 + $1.quantity }
                scaledWeight = ingTotal * servingMultiplier
            }

            FoodWeightLabel?.text = "  Weight total  \(Int(scaledWeight)) g  "

            print("DEBUG: Weight label updated: Weight total \(Int(scaledWeight)) g")
        }

        private func updateMacros() {
            guard let baseFood = baseFood else { return }

            var multipliedFood = baseFood
            multipliedFood.proteinContent = baseFood.proteinContent * servingMultiplier
            multipliedFood.carbsContent = baseFood.carbsContent * servingMultiplier
            multipliedFood.fatsContent = baseFood.fatsContent * servingMultiplier

            multipliedFood.servingSize = baseFood.servingSize
            multipliedFood.weight = baseFood.servingSize * servingMultiplier

            if let customCalories = baseFood.customCalories {
                multipliedFood.customCalories = customCalories * servingMultiplier
            }

            if let ingredients = baseFood.ingredients {
                multipliedFood.ingredients = ingredients.map { ingredient in
                    var newIngredient = ingredient
                    newIngredient.quantity = ingredient.quantity * servingMultiplier
                    return newIngredient
                }
            }

            headerView.configure(with: multipliedFood)
        }

        static func present(from viewController: UIViewController, with food: Food) {
            guard let storyboard = viewController.storyboard ?? UIStoryboard(name: "Main", bundle: nil) as UIStoryboard? else {
                print("Error: Could not load storyboard")
                return
            }

            guard let ingredientVC = storyboard.instantiateViewController(withIdentifier: "foodLogIngredientViewController") as? FoodLogIngredientViewController else {
                print("Error: Could not instantiate foodLogIngredientViewController")
                return
            }

            ingredientVC.food = food

            if let navController = viewController.navigationController {
                navController.pushViewController(ingredientVC, animated: true)
            } else {
                print("Error: No navigation controller found")
            }
        }
    }

extension FoodLogIngredientViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return food.ingredients?.count ?? 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if food.ingredients?.isEmpty == true {
            let cell = tableView.dequeueReusableCell(withIdentifier: FoodIngredientListTableViewCell.identifier, for: indexPath) as! FoodIngredientListTableViewCell
            cell.IngredientNameLabel.text = food.name
            return cell
        }
        else {
            let cell = tableView.dequeueReusableCell(withIdentifier: FoodIngredientListTableViewCell.identifier, for: indexPath) as! FoodIngredientListTableViewCell

            let ingredient = food.ingredients?[indexPath.row] ?? defaultIngredient
            cell.configureCell(with: ingredient)

            return cell
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        60
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Ingredients"
    }

}
