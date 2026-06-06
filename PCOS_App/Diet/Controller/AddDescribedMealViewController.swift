import UIKit
import FoundationModels

protocol AddDescribedMealDelegate: AnyObject {
    func didConfirmMeal(_ food: Food)
}

class AddDescribedMealViewController: UIViewController {

    @IBOutlet weak var foodName: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var FoodWeightLabel: UILabel!
    @IBOutlet weak var servingNumberLabel: UILabel!
    @IBOutlet weak var servingStepper: UIStepper!
    @IBOutlet weak var foodWeightView: UIView!

    @IBOutlet weak var recommendationLabel: UILabel!
    @IBOutlet weak var recommendationView: UIView!
    var foodItem: FoodItem!
    var food: Food?
    weak var delegate: AddDescribedMealDelegate?
    var isReadOnlyIngredients: Bool = false
    private var loadingView: UIView?
    private var servingMultiplier: Double = 1.0
    private var headerView: FoodLogIngredientHeader!
    private var ingredients: [Ingredient] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        guard foodItem != nil || food != nil else {
            print("ERROR: Both foodItem and food are nil!")
            dismiss(animated: true)
            return
        }

        loadIngredients()
        setupUI()
        setupTableView()
        setupHeader()
        setupStepper()
        setupServingLabel()
        setupWeightLabel()
        setupRecommendationView()

        navigationController?.navigationBar.prefersLargeTitles = false
        title = "Confirm Meal"

        Task { await fetchMealInsight() }

        print("DEBUG: Loaded with \(ingredients.count) ingredients")
    }

    private func setupUI() {
        foodName.font = .systemFont(ofSize: 22, weight: .bold)
        foodName.numberOfLines = 0
    }

    private func setupRecommendationView() {
        guard let card = recommendationView, let label = recommendationLabel else { return }

        card.layer.cornerRadius = 12
        card.clipsToBounds = true

        label.font = .systemFont(ofSize: 13, weight: .regular)
        label.textColor = UIColor(red: 0.35, green: 0.25, blue: 0.05, alpha: 1)
        label.numberOfLines = 0
        label.text = "Analysing your meal…"
        label.textColor = .secondaryLabel
    }

    private func fetchMealInsight() async {

        guard case .available = SystemLanguageModel.default.availability else {
            await MainActor.run { showFallbackInsight() }
            return
        }

        var totalProtein = 0.0, totalCarbs = 0.0, totalFat = 0.0, totalFibre = 0.0
        for ingredient in ingredients {
            let factor = ingredient.quantity / 100.0
            totalProtein += ingredient.protein * factor
            totalCarbs   += ingredient.carbs   * factor
            totalFat     += ingredient.fats    * factor
            totalFibre   += ingredient.fibre   * factor
        }

        totalProtein *= servingMultiplier
        totalCarbs   *= servingMultiplier
        totalFat     *= servingMultiplier
        totalFibre   *= servingMultiplier
        let calories = Int((totalProtein * 4) + (totalCarbs * 4) + (totalFat * 9))

        let mealName = foodItem?.name ?? food?.name ?? "this meal"
        let ingredientNames = ingredients.prefix(4).map { $0.name }.joined(separator: ", ")

        let allTags = Set(ingredients.flatMap { $0.tags }).filter { $0 != .none }
        let tagDescriptions: [String: String] = [
            "pcosFriendly": "PCOS-friendly",
            "pcosTrigger": "PCOS trigger",
            "highProtein": "high protein",
            "lowProtein": "low protein",
            "highFibre": "high fibre",
            "lowFibre": "low fibre",
            "healthyFats": "contains healthy fats",
            "unhealthyFats": "contains unhealthy fats",
            "highGlycemic": "high glycaemic index",
            "mediumGlycemic": "medium glycaemic index",
            "lowGlycemic": "low glycaemic index",
            "insulinSpiking": "insulin spiking",
            "insulinBalancing": "insulin balancing",
            "highInsulinLoad": "high insulin load",
            "lowInsulinLoad": "low insulin load",
            "antiInflammatory": "anti-inflammatory",
            "proInflammatory": "pro-inflammatory",
            "highCarb": "high carb",
            "lowCarb": "low carb",
            "bloatingTrigger": "may cause bloating",
            "bloatingReducer": "reduces bloating",
            "gutFriendly": "gut-friendly",
            "gasForming": "gas-forming",
            "moodBoost": "supports mood",
            "energyBoost": "boosts energy",
            "ultraProcessed": "ultra-processed",
            "processed": "processed",
            "wholeFood": "whole food",
            "estrogenBoosting": "estrogen boosting",
            "androgenBoosting": "androgen boosting",
            "androgenLowering": "androgen lowering",
            "sugary": "sugary",
            "noAddedSugar": "no added sugar",
            "crampTrigger": "may trigger cramps",
            "crampReducer": "reduces cramps"
        ]
        let tagLabels = allTags
            .compactMap { tagDescriptions[$0.rawValue] }
            .sorted()
            .joined(separator: ", ")
        let tagLine = tagLabels.isEmpty ? "No specific health tags available." : "Verified tags: \(tagLabels)."

        let instructions = """
        You are a supportive, realistic nutrition coach for a woman with PCOS.
        Reply in exactly 1-2 short, simple sentences.

        Evaluation Rules:
        1. IF the meal already contains a good source of protein or fiber (e.g., veggies, beans, dal, eggs, meat), PRAISE her and DO NOT suggest any improvements. Be fully satisfied with the meal.
        2. IF it is a "cheat meal" or highly unbalanced (e.g., mostly sweets or refined carbs with no protein/fiber), be warm and guilt-free (e.g., "It's totally okay to enjoy your favorite treats!"). Suggest ONE simple addition (like pairing with nuts or taking a short walk) to help balance blood sugar.

        CRITICAL: Never nitpick. If she already added healthy elements, just appreciate it.
        """

        let prompt = """
        Meal: \(mealName) (\(calories) kcal) — Protein \(Int(totalProtein))g, Carbs \(Int(totalCarbs))g, Fat \(Int(totalFat))g
        Ingredients: \(ingredientNames)
        \(tagLine)

        Provide 1-2 short sentences following the Evaluation Rules exactly.
        """

        do {
            let result = try await AIBrain.shared.generateResponse(prompt: prompt, instructions: instructions)
            let insight = result

            await MainActor.run {
                guard let label = recommendationLabel, let card = recommendationView else { return }
                label.text = insight
                label.textColor = UIColor(red: 0.35, green: 0.25, blue: 0.05, alpha: 1)
                card.alpha = 0
                UIView.animate(withDuration: 0.35) { card.alpha = 1 }
            }
        } catch {
            print("DEBUG: AI meal insight failed — \(error)")
            await MainActor.run { showFallbackInsight() }
        }
    }

    private func showFallbackInsight() {
        guard let label = recommendationLabel, let card = recommendationView else { return }

        let allTags = Set(ingredients.flatMap { $0.tags })

        var totalProtein = 0.0, totalCarbs = 0.0, totalFat = 0.0, totalFibre = 0.0
        for ingredient in ingredients {
            let factor = ingredient.quantity / 100.0
            totalProtein += ingredient.protein * factor
            totalCarbs   += ingredient.carbs   * factor
            totalFat     += ingredient.fats    * factor
            totalFibre   += ingredient.fibre   * factor
        }
        totalProtein *= servingMultiplier
        totalCarbs   *= servingMultiplier
        totalFat     *= servingMultiplier
        totalFibre   *= servingMultiplier

        var lines: [String] = []

        if allTags.contains(.pcosFriendly) {
            lines.append("This meal has PCOS-friendly ingredients.")
        }
        if allTags.contains(.highProtein) || totalProtein >= 15 {
            lines.append("Good protein content (\(Int(totalProtein))g) — supports hormone balance.")
        }
        if allTags.contains(.antiInflammatory) {
            lines.append("Contains anti-inflammatory ingredients — great for PCOS.")
        }
        if allTags.contains(.lowGlycemic) || allTags.contains(.insulinBalancing) {
            lines.append("Low-GI choice — helps keep insulin stable.")
        }
        if allTags.contains(.highFibre) || totalFibre >= 5 {
            lines.append("High fibre — supports gut health and steady energy.")
        }

        if allTags.contains(.highGlycemic) || allTags.contains(.insulinSpiking) {
            lines.append("This meal may spike insulin — pair it with protein or a handful of nuts to slow absorption.")
        }
        if allTags.contains(.pcosTrigger) {
            lines.append("Some ingredients here may trigger PCOS symptoms — enjoy in moderation.")
        }
        if allTags.contains(.ultraProcessed) {
            lines.append("This is heavily processed — a whole-food swap would be a great upgrade when possible.")
        }
        if allTags.contains(.proInflammatory) {
            lines.append("Contains pro-inflammatory ingredients — balancing it with leafy greens helps.")
        }
        if allTags.contains(.bloatingTrigger) {
            lines.append("May cause bloating — a small serving of dahi (yogurt) alongside can help.")
        }

        if lines.isEmpty {
            if totalProtein < 10 {
                lines.append("This meal is low in protein — consider adding dal, paneer, or eggs to support hormone balance.")
            } else if totalCarbs > 60 {
                lines.append("High in carbs — pairing with a protein source like dahi or sprouts will keep your insulin steadier.")
            } else {
                lines.append("This meal looks balanced overall — enjoy it mindfully as part of your day!")
            }
        }

        label.text = lines.prefix(2).joined(separator: " ")
        label.textColor = UIColor(red: 0.35, green: 0.25, blue: 0.05, alpha: 1)
        card.isHidden = false
        card.alpha = 0
        UIView.animate(withDuration: 0.35) { card.alpha = 1 }
    }

    private func loadIngredients() {
        if let food = food {
            ingredients = food.ingredients ?? []
            foodName.text = food.name
        } else if let foodItem = foodItem {
            ingredients = foodItem.ingredients
            foodName.text = foodItem.name
        }
        print("DEBUG: Loaded \(ingredients.count) ingredients")
    }

    private func setupHeader() {
        guard let containerView = foodWeightView else {
            print("ERROR: foodWeightView is nil!")
            return
        }

        containerView.subviews.forEach { $0.removeFromSuperview() }
        containerView.backgroundColor = .white
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

        updateHeaderWithCurrentIngredients()
    }

    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self

        tableView.layer.cornerRadius = 12
        tableView.clipsToBounds = true
    }

    private func setupStepper() {
        guard let stepper = servingStepper else {
            print("Error: servingStepper outlet is not connected!")
            return
        }

        stepper.minimumValue = 0.5
        stepper.maximumValue = 10.0
        stepper.stepValue = 0.5

        stepper.value = 1.0
        servingMultiplier = 1.0

        stepper.tintColor = .label
        stepper.layer.cornerRadius = 10
        stepper.clipsToBounds = true

        stepper.addTarget(self, action: #selector(servingStepperChanged(_:)), for: .valueChanged)
    }

    @objc private func servingStepperChanged(_ sender: UIStepper) {
        servingMultiplier = sender.value
        updateServingLabel()
        updateWeightLabel()
        updateHeaderWithCurrentIngredients()
    }

    private func updateServingLabel() {
        guard let label = servingNumberLabel else { return }
        if servingMultiplier == 1.0 {
            label.text = "1 serving"
        } else {
            label.text = servingMultiplier.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f servings", servingMultiplier) : String(format: "%.1f servings", servingMultiplier)
        }
    }

    private func setupServingLabel() {
        guard let label = servingNumberLabel else { return }
        label.font = .systemFont(ofSize: 18, weight: .medium)
        label.textColor = .label
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.7
        updateServingLabel()
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

        updateWeightLabel()
    }

    private func updateWeightLabel() {
        guard let label = FoodWeightLabel else { return }

        let totalRecipeWeight = ingredients.reduce(0.0) { $0 + $1.quantity }
        let servingSize = foodItem?.servingSize ?? food?.servingSize ?? 100

        let displayWeight: Double
        if totalRecipeWeight > 0 && totalRecipeWeight != servingSize {
            displayWeight = servingSize * servingMultiplier
        } else {
            displayWeight = totalRecipeWeight * servingMultiplier
        }

        label.text = String(format: "  Weight Total  %.0f g  ", displayWeight)
    }

    private func updateHeaderWithCurrentIngredients() {
        if isReadOnlyIngredients, let f = food {
            let totalProtein = f.proteinContent * servingMultiplier
            let totalCarbs = f.carbsContent * servingMultiplier
            let totalFat = f.fatsContent * servingMultiplier
            let totalCalories = Int((totalProtein * 4) + (totalCarbs * 4) + (totalFat * 9))

            let tempFoodItem = FoodItem(
                id: f.id.hashValue,
                name: f.name,
                calories: totalCalories,
                image: f.image ?? "dietPlaceholder",
                servingSize: f.servingSize,
                protein: totalProtein,
                carbs: totalCarbs,
                fat: totalFat,
                isSelected: false,
                desc: f.desc,
                ingredients: ingredients
            )
            headerView.configure(with: tempFoodItem)
            return
        }

        guard !ingredients.isEmpty else {
            print("DEBUG: No ingredients to calculate macros")
            return
        }

        var totalProtein: Double = 0
        var totalCarbs: Double = 0
        var totalFat: Double = 0

        for ingredient in ingredients {
            let factor = ingredient.quantity / 100.0
            totalProtein += ingredient.protein * factor
            totalCarbs += ingredient.carbs * factor
            totalFat += ingredient.fats * factor
        }

        totalProtein *= servingMultiplier
        totalCarbs *= servingMultiplier
        totalFat *= servingMultiplier

        print("DEBUG: Calculated macros - P: \(totalProtein), C: \(totalCarbs), F: \(totalFat)")

        let tempFoodItem = FoodItem(
            id: foodItem?.id ?? 0,
            name: foodItem?.name ?? food?.name ?? "Described Meal",
            calories: Int((totalProtein * 4) + (totalCarbs * 4) + (totalFat * 9)),
            image: (foodItem?.image ?? food?.image) ?? "dietPlaceholder",
            servingSize: foodItem?.servingSize ?? food?.servingSize ?? 1,
            protein: totalProtein,
            carbs: totalCarbs,
            fat: totalFat,
            isSelected: false,
            desc: foodItem?.desc ?? food?.desc ?? "",
            ingredients: ingredients
        )

        headerView.configure(with: tempFoodItem)
        print("DEBUG: Header updated with calculated macros")
    }

    @IBAction func saveButtonTapped(_ sender: Any) {

            guard let finalFood = createFinalFoodObject() else {
                print("ERROR: Could not create final food object")
                showAlert(message: "Failed to create meal. Please try again.")
                return
            }

            print("DEBUG: Final food created: \(finalFood.name)")
            print("DEBUG: Protein: \(finalFood.proteinContent)g, Carbs: \(finalFood.carbsContent)g, Fats: \(finalFood.fatsContent)g")
            print("DEBUG: Delegate is: \(delegate != nil ? "set" : "nil")")

            delegate?.didConfirmMeal(finalFood)
            print("DEBUG: Delegate called - meal should be saved now")

            if let nav = navigationController {

                if let presentingVC = nav.presentingViewController {

                    presentingVC.dismiss(animated: true) {
                        print("DEBUG: Navigation controller dismissed")
                    }
                } else {

                    nav.popToRootViewController(animated: true)
                    print("DEBUG: Popped to root")
                }
            } else if presentingViewController != nil {

                dismiss(animated: true) {
                    print("DEBUG: View controller dismissed")
                }
            }

            print("DEBUG: Save button completed")
    }

    private func createFinalFoodObject() -> Food? {
        var totalProtein: Double = 0
        var totalCarbs: Double = 0
        var totalFat: Double = 0

        let totalRecipeWeight = ingredients.reduce(0.0) { $0 + $1.quantity }
        let servingSize = foodItem?.servingSize ?? food?.servingSize ?? 100

        let finalWeight: Double
        if totalRecipeWeight > 0 && totalRecipeWeight != servingSize {
            finalWeight = servingSize * servingMultiplier
        } else {
            finalWeight = totalRecipeWeight * servingMultiplier
        }

        if isReadOnlyIngredients, let f = food {
             totalProtein = f.proteinContent * servingMultiplier
             totalCarbs = f.carbsContent * servingMultiplier
             totalFat = f.fatsContent * servingMultiplier
        } else {
            for ingredient in ingredients {
                let factor = ingredient.quantity / 100.0
                totalProtein += ingredient.protein * factor
                totalCarbs += ingredient.carbs * factor
                totalFat += ingredient.fats * factor
            }

            totalProtein *= servingMultiplier
            totalCarbs *= servingMultiplier
            totalFat *= servingMultiplier
        }

        let totalCalories = (totalProtein * 4) + (totalCarbs * 4) + (totalFat * 9)
        if let food = food {
            return Food(
                id: UUID(),
                name: food.name,
                image: food.image,
                timeStamp: Date(),
                servingSize: food.servingSize,
                weight: finalWeight,
                desc: food.desc,
                proteinContent: totalProtein,
                carbsContent: totalCarbs,
                fatsContent: totalFat,
                customCalories: totalCalories,
                tags: food.tags,
                ingredients: ingredients
            )
        } else if let foodItem = foodItem {
            return Food(
                id: UUID(),
                name: foodItem.name,
                image: foodItem.image,
                timeStamp: Date(),
                servingSize: foodItem.servingSize,
                weight: finalWeight,
                desc: foodItem.desc,
                proteinContent: totalProtein,
                carbsContent: totalCarbs,
                fatsContent: totalFat,
                customCalories: totalCalories,
                tags: [],
                ingredients: ingredients
            )
        }

        return nil
    }

    @IBAction func cancelButtonTapped(_ sender: Any) {
        dismiss(animated: true)
    }

    private func showAlert(message: String) {
        let alert = UIAlertController(
            title: "Notice",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

extension AddDescribedMealViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return max(ingredients.count, 1)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "cell")
        if cell == nil {
            cell = UITableViewCell(style: .value1, reuseIdentifier: "cell")
        }
        let activeCell = cell!

        if ingredients.isEmpty {
            activeCell.textLabel?.text = "No ingredients available"
            activeCell.textLabel?.textColor = .secondaryLabel
            activeCell.detailTextLabel?.text = nil
            activeCell.selectionStyle = .none
        } else {
            let ingredient = ingredients[indexPath.row]
            activeCell.textLabel?.text = ingredient.name
            activeCell.textLabel?.textColor = .label
            activeCell.detailTextLabel?.text = nil
            activeCell.selectionStyle = .default
        }

        return activeCell
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = .clear

        let titleLabel = UILabel()
        titleLabel.text = "Edit Ingredients"
        titleLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        titleLabel.textColor = .secondaryLabel
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(titleLabel)

        let addButton = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)
        addButton.setImage(UIImage(systemName: "plus", withConfiguration: config), for: .normal)
        addButton.tintColor = UIColor(red: 0.996, green: 0.478, blue: 0.588, alpha: 1.0)
        addButton.translatesAutoresizingMaskIntoConstraints = false
        addButton.addTarget(self, action: #selector(addIngredientTapped), for: .touchUpInside)

        if isReadOnlyIngredients {
            addButton.isHidden = true
        }

        headerView.addSubview(addButton)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),

            addButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            addButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            addButton.widthAnchor.constraint(equalToConstant: 44),
            addButton.heightAnchor.constraint(equalToConstant: 44)
        ])

        return headerView
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if isReadOnlyIngredients { return }
        if !ingredients.isEmpty {
            let ingredient = ingredients[indexPath.row]
            showEditIngredient(ingredient, at: indexPath)
        }
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if isReadOnlyIngredients { return false }
        return !ingredients.isEmpty
    }

    func tableView(
        _ tableView: UITableView,
        commit editingStyle: UITableViewCell.EditingStyle,
        forRowAt indexPath: IndexPath
    ) {
        if editingStyle == .delete {
            guard ingredients.count > 1 else {
                showAlert(message: "Cannot delete the only ingredient in this meal.")
                return
            }
            let ingredient = ingredients[indexPath.row]
            showDeleteConfirmation(for: ingredient, at: indexPath)
        }
    }

    func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        if isReadOnlyIngredients { return nil }
        guard !ingredients.isEmpty else { return nil }

        guard ingredients.count > 1 else {
            let infoAction = UIContextualAction(
                style: .normal,
                title: "Can't Delete"
            ) { [weak self] (_, _, completionHandler) in
                self?.showAlert(message: "Cannot delete the only ingredient in this meal.")
                completionHandler(true)
            }
            infoAction.backgroundColor = .systemGray
            let config = UISwipeActionsConfiguration(actions: [infoAction])
            config.performsFirstActionWithFullSwipe = false
            return config
        }

        let deleteAction = UIContextualAction(
            style: .destructive,
            title: "Delete"
        ) { [weak self] (_, _, completionHandler) in
            guard let self = self else {
                completionHandler(false)
                return
            }
            let ingredient = self.ingredients[indexPath.row]
            self.showDeleteConfirmation(for: ingredient, at: indexPath)
            completionHandler(true)
        }

        deleteAction.backgroundColor = .systemRed
        deleteAction.image = UIImage(systemName: "trash.fill")

        let configuration = UISwipeActionsConfiguration(actions: [deleteAction])
        configuration.performsFirstActionWithFullSwipe = false
        return configuration
    }

    private func showDeleteConfirmation(for ingredient: Ingredient, at indexPath: IndexPath) {
        let alert = UIAlertController(
            title: "Delete Ingredient",
            message: "Remove '\(ingredient.name)' from this meal?",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            self?.deleteIngredient(at: indexPath)
        })

        present(alert, animated: true)
    }

    private func deleteIngredient(at indexPath: IndexPath) {
        let ingredient = ingredients[indexPath.row]
        print("DEBUG: Deleting ingredient: \(ingredient.name)")

        ingredients.remove(at: indexPath.row)

        if ingredients.isEmpty {
            tableView.reloadData()
        } else {
            tableView.deleteRows(at: [indexPath], with: .fade)
        }

        updateHeaderWithCurrentIngredients()
        updateWeightLabel()

        print("DEBUG: \(ingredients.count) ingredients remaining")
    }

    private func showEditIngredient(_ ingredient: Ingredient, at indexPath: IndexPath) {
        let alert = UIAlertController(
            title: "Edit Ingredient",
            message: "Edit quantity for \(ingredient.name)",
            preferredStyle: .alert
        )

        alert.addTextField { textField in
            textField.placeholder = "Quantity (grams)"
            textField.keyboardType = .decimalPad
            textField.text = "\(Int(ingredient.quantity))"
        }

        alert.addTextField { textField in
            textField.placeholder = "Unit"
            textField.text = ingredient.unit
        }

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            guard let self = self else { return }

            let quantityText = alert.textFields?[0].text ?? "100"
            let unitText = alert.textFields?[1].text ?? "g"

            if let newQuantity = Double(quantityText) {
                self.ingredients[indexPath.row].quantity = newQuantity
                self.ingredients[indexPath.row].unit = unitText

                self.tableView.reloadRows(at: [indexPath], with: .automatic)
                self.updateHeaderWithCurrentIngredients()
                self.updateWeightLabel()

                Task { await self.fetchMealInsight() }
            }
        })

        present(alert, animated: true)
    }

    @objc private func addIngredientTapped() {
        let alert = UIAlertController(
            title: "Add Ingredient",
            message: "Describe the ingredient and amount (e.g. '1 boiled egg' or '50g paneer')",
            preferredStyle: .alert
        )

        alert.addTextField { textField in
            textField.placeholder = "e.g. 50g paneer"
        }

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Add", style: .default) { [weak self] _ in
            guard let self = self, let text = alert.textFields?.first?.text, !text.isEmpty else { return }
            Task {
                await self.fetchIngredientNutritionalData(description: text)
            }
        })

        present(alert, animated: true)
    }

    private func fetchIngredientNutritionalData(description: String) async {
        let instructions = """
        You are a professional nutritionist specializing in Indian and international foods.
        When given an ingredient and its amount, return ONLY a valid JSON object with NO extra text,
        NO markdown, NO code blocks, NO explanation — just raw JSON.

        The JSON must follow this exact structure representing a SINGLE ingredient:
        {
          "name": "ingredient name",
          "quantity": 50.0,
          "unit": "g",
          "protein": 5.0,
          "carbs": 20.0,
          "fats": 3.0,
          "fibre": 1.0
        }

        Rules:
        - All numeric values must be doubles or integers (no strings for numbers)
        - quantity is the ACTUAL weight of the ingredient described in grams (e.g. if user says 1 boiled egg, quantity is ~50.0)
        - protein, carbs, fats, fibre are the macros PER 100G of that ingredient.
        - Return ONLY the JSON, nothing else.
        """

        await MainActor.run { self.showLoadingIndicator(message: "Analyzing ingredient...") }

        do {
            let responseText = try await AIBrain.shared.analyzeMealDescription(description: description, instructions: instructions)
            print("DEBUG: Ingredient AI Model response:\n\(responseText)")

            var cleaned = responseText.trimmingCharacters(in: .whitespacesAndNewlines)
            if cleaned.hasPrefix("```json") {
                cleaned = String(cleaned.dropFirst(7))
            } else if cleaned.hasPrefix("```") {
                cleaned = String(cleaned.dropFirst(3))
            }
            if cleaned.hasSuffix("```") {
                cleaned = String(cleaned.dropLast(3))
            }
            cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)

            guard let data = cleaned.data(using: .utf8) else { throw URLError(.badServerResponse) }
            let rawIngredient = try JSONDecoder().decode(AIIngredient.self, from: data)

            let newIngredient = Ingredient(
                id: UUID(),
                name: rawIngredient.name,
                quantity: rawIngredient.quantity,
                weight: rawIngredient.quantity,
                unit: rawIngredient.unit,
                protein: rawIngredient.protein,
                carbs: rawIngredient.carbs,
                fats: rawIngredient.fats,
                fibre: rawIngredient.fibre,
                tags: [.none]
            )

            await MainActor.run {
                self.hideLoadingIndicator()
                self.ingredients.append(newIngredient)
                self.tableView.reloadData()
                self.updateHeaderWithCurrentIngredients()
                self.updateWeightLabel()

                Task { await self.fetchMealInsight() }
            }

        } catch {
            print("ERROR: AI Ingredient parsing failed: \(error)")
            await MainActor.run {
                self.hideLoadingIndicator()
                self.showAlert(message: "Could not add ingredient. Please try a clearer description.")
            }
        }
    }

    private func showLoadingIndicator(message: String) {
        let overlay = UIView(frame: view.bounds)
        overlay.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        overlay.tag = 888

        let activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.center = overlay.center
        activityIndicator.color = .white
        activityIndicator.startAnimating()

        let label = UILabel()
        label.text = message
        label.textColor = .white
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textAlignment = .center
        label.frame = CGRect(
            x: 0,
            y: activityIndicator.frame.maxY + 20,
            width: view.bounds.width,
            height: 30
        )

        overlay.addSubview(activityIndicator)
        overlay.addSubview(label)
        view.addSubview(overlay)
        view.isUserInteractionEnabled = false
    }

    private func hideLoadingIndicator() {
        view.viewWithTag(888)?.removeFromSuperview()
        view.isUserInteractionEnabled = true
    }
}
