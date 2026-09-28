import UIKit

/// Displays two AI-generated daily mission cards with completion state.
///
/// Why this exists:
/// Renders persisted GoalCards with live progress feedback.
/// On completion, the card transforms in place — showing a ✓ badge and
/// celebration message — without removing the card from the layout.
class DailyGoalsCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var Goal1View: UIView!
    @IBOutlet weak var GoalImage_1: UIImageView!
    @IBOutlet weak var GoalCategory_1: UILabel!
    @IBOutlet weak var GoalTitle_1: UILabel!
    @IBOutlet weak var GoalDescription_1: UILabel!

    @IBOutlet weak var Goal2View: UIView!
    @IBOutlet weak var GoalImage_2: UIImageView!
    @IBOutlet weak var GoalCategory_2: UILabel!
    @IBOutlet weak var GoalTitle_2: UILabel!
    @IBOutlet weak var GoalDescription_2: UILabel!

    static let identifier = "DailyGoalsCollectionViewCell"
    static func nib() -> UINib {
        return UINib(nibName: identifier, bundle: nil)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        styleGoalView(Goal1View)
        styleGoalView(Goal2View)
        showLoadingState()
    }

    ///
    /// Configures both goal cards from a DailyGoalsOutput.
    ///
    /// Why this exists:
    /// HomeViewController calls this every time the goals state updates.
    /// Completion detection is driven by `currentValue >= targetValue`.
    ///
    /// - Parameter output: The current DailyGoalsOutput with updated progress.
    func configure(with output: DailyGoalsOutput) {
        let goals = output.goals
        if goals.count > 0 {
            let isCompleted1 = isGoalCompleted(goals[0])
            configureGoal(goals[0], view: Goal1View,
                          image: GoalImage_1, category: GoalCategory_1,
                          title: GoalTitle_1, desc: GoalDescription_1,
                          isCompleted: isCompleted1)
        }
        if goals.count > 1 {
            let isCompleted2 = isGoalCompleted(goals[1])
            configureGoal(goals[1], view: Goal2View,
                          image: GoalImage_2, category: GoalCategory_2,
                          title: GoalTitle_2, desc: GoalDescription_2,
                          isCompleted: isCompleted2)
        }
    }

    ///
    /// Renders a skeleton loading state while goals are being generated.
    ///
    func showLoadingState() {
        for (title, desc, cat) in [
            (GoalTitle_1, GoalDescription_1, GoalCategory_1),
            (GoalTitle_2, GoalDescription_2, GoalCategory_2)
        ] {
            title?.text = "Generating goal..."
            title?.textAlignment = .center
            title?.textColor = .tertiaryLabel
            desc?.text = ""
            cat?.text = ""
        }
    }

    // MARK: - Private

    ///
    /// Determines whether the goal is completed.
    ///
    /// - Parameter goal: The GoalCard to evaluate.
    /// - Returns: True if the goal's completion threshold has been crossed.
    private func isGoalCompleted(_ goal: GoalCard) -> Bool {
        switch goal.completionRule {
        case "current>=target":
            return goal.targetValue > 0 && goal.currentValue >= goal.targetValue
        case "any":
            return goal.currentValue > 0
        default:
            return false
        }
    }

    ///
    /// Renders a single goal card with optional completion state overlay.
    ///
    /// Why this exists:
    /// When `isCompleted` is true, the card transforms in place:
    /// - Title remains visible (preserves layout)
    /// - Description shows the celebration message
    /// - A green ✓ badge replaces the category icon background
    /// - No card removal — the dopamine reward appears inside the same frame.
    ///
    private func configureGoal(
        _ goal: GoalCard,
        view: UIView,
        image: UIImageView,
        category: UILabel,
        title: UILabel,
        desc: UILabel,
        isCompleted: Bool
    ) {
        let color = isCompleted
            ? UIColor(red: 0.20, green: 0.65, blue: 0.35, alpha: 1)   // green on completion
            : categoryColor(goal.category)

        view.backgroundColor = UIColor.systemBackground
        view.layer.cornerRadius = 20
        view.layer.borderWidth = isCompleted ? 1.5 : 0
        view.layer.borderColor = isCompleted ? color.cgColor : UIColor.clear.cgColor

        // Icon background
        let bgTag = 999
        if let existing = image.superview?.viewWithTag(bgTag) {
            existing.backgroundColor = color
        } else if let parent = image.superview {
            let bg = UIView()
            bg.tag = bgTag
            bg.translatesAutoresizingMaskIntoConstraints = false
            bg.layer.cornerRadius = 8
            bg.layer.masksToBounds = true
            bg.backgroundColor = color
            parent.insertSubview(bg, belowSubview: image)
            NSLayoutConstraint.activate([
                bg.centerXAnchor.constraint(equalTo: image.centerXAnchor),
                bg.centerYAnchor.constraint(equalTo: image.centerYAnchor),
                bg.widthAnchor.constraint(equalToConstant: 34),
                bg.heightAnchor.constraint(equalToConstant: 34)
            ])
        }

        // Icon — show ✓ on completion
        let iconName = isCompleted ? "checkmark" : categoryIcon(goal.category)
        image.image = UIImage(systemName: iconName)?
            .withConfiguration(UIImage.SymbolConfiguration(pointSize: 12, weight: .medium))
        image.tintColor = .white

        // Category label
        category.text = isCompleted ? "Completed" : goal.category.capitalized
        category.textColor = color
        category.font = .systemFont(ofSize: 13, weight: .semibold)

        // Title — always visible to preserve layout
        title.text = goal.title
        title.font = .systemFont(ofSize: 16, weight: .medium)
        title.textColor = isCompleted ? .secondaryLabel : .label
        title.textAlignment = .left
        title.numberOfLines = 2

        // Description — show celebration message on completion
        if isCompleted {
            desc.text = goal.celebrationMessage
            desc.textColor = color
            desc.font = .systemFont(ofSize: 14, weight: .medium)
        } else {
            // Show progress for measurable goals
            let progressSuffix = progressText(for: goal)
            desc.text = progressSuffix.isEmpty ? goal.sentence : "\(goal.sentence)\n\(progressSuffix)"
            desc.font = .systemFont(ofSize: 14)
            desc.textColor = .secondaryLabel
        }
        desc.numberOfLines = 3

        // Animate completion appearance
        if isCompleted {
            animateCompletion(view: view, color: color)
        }
    }

    ///
    /// Returns a progress string for measurable goals (e.g. "27 / 57g protein").
    ///
    private func progressText(for goal: GoalCard) -> String {
        guard goal.targetValue > 0 else { return "" }
        switch goal.targetType {
        case "protein":
            return "\(Int(goal.currentValue)) / \(Int(goal.targetValue))g protein"
        case "workoutMinutes":
            return "\(Int(goal.currentValue)) / \(Int(goal.targetValue)) min"
        case "steps":
            return "\(Int(goal.currentValue)) / \(Int(goal.targetValue)) steps"
        default:
            return ""
        }
    }

    ///
    /// Plays a subtle scale + color pulse animation when a goal is first completed.
    ///
    private func animateCompletion(view: UIView, color: UIColor) {
        UIView.animate(
            withDuration: 0.3,
            delay: 0,
            usingSpringWithDamping: 0.6,
            initialSpringVelocity: 0.8,
            options: [],
            animations: {
                view.transform = CGAffineTransform(scaleX: 1.03, y: 1.03)
            },
            completion: { _ in
                UIView.animate(withDuration: 0.2) {
                    view.transform = .identity
                }
            }
        )
    }

    private func styleGoalView(_ view: UIView) {
        view.layer.cornerRadius = 12
        view.layer.masksToBounds = true
    }

    private func categoryColor(_ category: String) -> UIColor {
        let c = category.lowercased()
        if c.contains("diet")      { return UIColor(hex: "#e8624a") }
        if c.contains("nutrition") { return UIColor(red: 0.20, green: 0.65, blue: 0.35, alpha: 1) }
        if c.contains("exercise") || c.contains("workout") {
            return UIColor(red: 0.95, green: 0.50, blue: 0.10, alpha: 1)
        }
        if c.contains("sleep")     { return UIColor(red: 0.35, green: 0.30, blue: 0.85, alpha: 1) }
        if c.contains("symptom")   { return UIColor(red: 0.85, green: 0.25, blue: 0.45, alpha: 1) }
        return UIColor(red: 0.85, green: 0.25, blue: 0.45, alpha: 1)
    }

    private func categoryIcon(_ category: String) -> String {
        let c = category.lowercased()
        if c.contains("diet")      { return "fork.knife" }
        if c.contains("nutrition") { return "leaf.fill" }
        if c.contains("exercise") || c.contains("workout") {
            return "figure.strengthtraining.traditional"
        }
        if c.contains("sleep")     { return "moon.zzz.fill" }
        if c.contains("symptom")   { return "heart.text.clipboard" }
        return "star.fill"
    }
}
