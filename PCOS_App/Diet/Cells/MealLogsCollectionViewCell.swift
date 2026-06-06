import UIKit

protocol MealLogsCellDelegate: AnyObject {
    func didSelectMeal(_ food: Food)
    func didRequestDeleteMeal(at index: Int)
}

class MealLogsCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var tableView: UITableView!

    weak var delegate: MealLogsCellDelegate?
    var todaysFoods: [Food] = []

    static let identifier = "MealLogsCollectionViewCell"
    static func nib() -> UINib {
        return UINib(nibName: identifier, bundle: nil)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        setupTableView()
    }

    private func setupTableView() {
        tableView.register(LogsTableViewCell.nib(), forCellReuseIdentifier: LogsTableViewCell.identifier)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.separatorStyle = .none
        tableView.isScrollEnabled = false 
    }

    func configure(with foods: [Food], quote: String) {
        todaysFoods = foods
        tableView.reloadData()
    }

    func desiredHeight() -> CGFloat {
        return CGFloat(todaysFoods.count) * 100
    }
}

extension MealLogsCollectionViewCell: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return todaysFoods.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: LogsTableViewCell.identifier,
            for: indexPath
        ) as! LogsTableViewCell
        cell.configure(with: todaysFoods[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        delegate?.didSelectMeal(todaysFoods[indexPath.row])
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return !todaysFoods.isEmpty
    }

    func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        guard !todaysFoods.isEmpty else { return nil }

        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") {
            [weak self] _, _, done in
            self?.delegate?.didRequestDeleteMeal(at: indexPath.row)
            done(true)
        }
        deleteAction.backgroundColor = .systemRed
        deleteAction.image = UIImage(systemName: "trash.fill")

        let config = UISwipeActionsConfiguration(actions: [deleteAction])
        config.performsFirstActionWithFullSwipe = false
        return config
    }
}
