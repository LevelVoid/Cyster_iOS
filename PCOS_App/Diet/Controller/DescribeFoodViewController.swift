//
// DescribeFoodViewController.swift
//
// Purpose:
// Allows users to log their meals by describing them in natural language.
//
// Why this exists:
// Provides an AI-powered alternative to manual search and scanning for quick meal logging.
//

import UIKit

class DescribeFoodViewController: UIViewController {

    @IBOutlet weak var dietInfoLabel: UILabel!
    @IBOutlet weak var describeYourMealText: UITextField!

    @IBOutlet weak var closeButton: UIBarButtonItem!
    @IBOutlet weak var doneButton: UIBarButtonItem!

    weak var dietDelegate: AddDescribedMealDelegate?

    private var loadingView: UIView?
    private var activityIndicator: UIActivityIndicatorView?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Add with AI"
        view.backgroundColor = .systemBackground
        setupUI()

        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
    }

    @IBAction func close(_ sender: Any) {
        dismiss(animated: true)
    }

    @IBAction func done(_ sender: Any) {
        guard let text = describeYourMealText.text,
              !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            showAlert(message: "Please describe your meal")
            return
        }

        showLoadingIndicator()
        Task {
            await analyzeMealWithFoundationModel(description: text)
        }
    }

    /// Analyzes the user's meal description using AI and navigates to the add screen.
    ///
    /// Parameters:
    ///   - description: The natural language text entered by the user.
    /// Returns: Void
    /// Throws: None (handles errors internally)
    private func analyzeMealWithFoundationModel(description: String) async {
        do {
            let food = try await AIBrain.shared.analyzeMealDescription(description: description)

            await MainActor.run {
                self.hideLoadingIndicator()
                self.parseAndNavigate(food: food, originalInput: description)
            }

        } catch {
            print("ERROR: AI Model failed: \(error)")
            await MainActor.run {
                self.hideLoadingIndicator()
                self.showAlert(message: "AI analysis failed. Please try again.\n\nError: \(error.localizedDescription)")
            }
        }
    }

    /// Parses the resulting Food object and navigates to the add screen.
    ///
    /// Parameters:
    ///   - food: The parsed Food object from the AI model.
    ///   - originalInput: The text input provided by the user.
    /// Returns: Void
    /// Throws: None
    private func parseAndNavigate(food: Food, originalInput: String) {
        let ingredients: [Ingredient] = food.ingredients ?? []

        guard !ingredients.isEmpty else {
            showAlert(message: "No ingredients found in AI response. Please try again.")
            return
        }

        let foodItem = FoodItem(
            id: Int.random(in: 100000...999999),
            name: food.name,
            calories: Int(food.calories),
            image: "dietPlaceholder",
            servingSize: food.servingSize,
            unit: "g",
            protein: food.proteinContent,
            carbs: food.carbsContent,
            fat: food.fatsContent,
            fiber: food.fiberContent,
            isSelected: false,
            desc: food.desc,
            ingredients: ingredients,
            confidence: food.confidence
        )

        print("DEBUG: Parsed FoodItem - \(foodItem.name), \(ingredients.count) ingredients")
        navigateToAdd(foodItem)
    }

    private func navigateToAdd(_ foodItem: FoodItem) {
        let storyboard = self.storyboard ?? UIStoryboard(name: "Diet", bundle: nil)

        if let vc = storyboard.instantiateViewController(
            withIdentifier: "AddDescribedMealViewController"
        ) as? AddDescribedMealViewController {
            vc.foodItem = foodItem
            vc.delegate = dietDelegate
            let nav = UINavigationController(rootViewController: vc)
            nav.modalPresentationStyle = .pageSheet
            if let sheet = nav.sheetPresentationController {
                if #available(iOS 16.0, *) {
                    sheet.detents = [.medium(), .large()]
                    sheet.prefersGrabberVisible = true
                    sheet.selectedDetentIdentifier = .large
                }
            }
            present(nav, animated: true)
        } else {
            showAlert(message: "Could not load meal confirmation screen.")
        }
    }

    private func setupUI() {
        describeYourMealText.placeholder = "e.g., 2 roti with dal and curd"
        describeYourMealText.autocapitalizationType = .none
        describeYourMealText.autocorrectionType = .no

        dietInfoLabel.text = "Nutrition values are AI estimates. Results may vary."
        dietInfoLabel.numberOfLines = 0
        dietInfoLabel.layer.cornerRadius = 20
        dietInfoLabel.clipsToBounds = true
        dietInfoLabel.font = .systemFont(ofSize: 14)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    private func showAlert(message: String) {
        let alert = UIAlertController(
            title: "Notice", message: message, preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func showLoadingIndicator() {
        let loadingView = UIView(frame: view.bounds)
        loadingView.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        loadingView.tag = 999

        let activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.center = loadingView.center
        activityIndicator.color = .white
        activityIndicator.startAnimating()

        let label = UILabel()
        label.text = "AI is analyzing your meal..."
        label.textColor = .white
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textAlignment = .center
        label.frame = CGRect(
            x: 0,
            y: activityIndicator.frame.maxY + 20,
            width: view.bounds.width,
            height: 30
        )

        loadingView.addSubview(activityIndicator)
        loadingView.addSubview(label)
        view.addSubview(loadingView)

        self.loadingView = loadingView
        self.activityIndicator = activityIndicator

        doneButton.isEnabled = false
        describeYourMealText.isEnabled = false
        view.isUserInteractionEnabled = false
    }

    private func hideLoadingIndicator() {
        loadingView?.removeFromSuperview()
        loadingView = nil
        activityIndicator = nil
        view.viewWithTag(999)?.removeFromSuperview()

        doneButton.isEnabled = true
        describeYourMealText.isEnabled = true
        view.isUserInteractionEnabled = true
    }
}
