import UIKit

class ProfileTableViewController: UITableViewController {

    private let section0 = ["Health details"]
    private let features = ["Reminders"]
    private let privacy = ["Apps", "Devices"]

    private let headerView: UIView = {
        let view = UIView()
        return view
    }()

    @IBOutlet weak var profileImageView: UIImageView!

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.text = "Name"
        label.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        label.textAlignment = .center
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        setupNavigationBar()
        setupTableView()
        setupHeaderView()
        updateProfileName()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateProfileName()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        profileImageView.layer.cornerRadius = profileImageView.frame.size.width / 2
        profileImageView.layer.masksToBounds = true
    }

    private func setupNavigationBar() {
        title = "Profile"
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
    }

    private func setupTableView() {
        tableView.separatorStyle = .singleLine
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0)
        tableView.tableFooterView = UIView()

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ProfileActionCell")
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "SettingCell")
    }

    private func setupHeaderView() {

        headerView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 200)

        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(profileImageView)

        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(nameLabel)

        NSLayoutConstraint.activate([

            profileImageView.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            profileImageView.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 20),
            profileImageView.widthAnchor.constraint(equalToConstant: 100),
            profileImageView.heightAnchor.constraint(equalToConstant: 100),

            nameLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            nameLabel.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 12),
            nameLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20),
            nameLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -20)

        ])

        tableView.tableHeaderView = headerView
    }

    private func updateProfileName() {
        if let user = ProfileService.shared.getProfile(),
           let name = user.name, !name.isEmpty {
            nameLabel.text = name
        } else {
            nameLabel.text = "Add Your Name"
        }
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return section0.count
        case 1:
            return features.count
        case 2:
            return privacy.count
        default:
            return 0
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ProfileActionCell", for: indexPath)

            cell.textLabel?.text = section0[indexPath.row]
            cell.textLabel?.textColor = .label
            cell.textLabel?.font = UIFont.systemFont(ofSize: 17, weight: .regular)
            cell.accessoryType = .disclosureIndicator
            cell.selectionStyle = .default

            return cell
        }

        let cell = tableView.dequeueReusableCell(withIdentifier: "SettingCell", for: indexPath)

        if indexPath.section == 1 {
            cell.textLabel?.text = features[indexPath.row]
        } else if indexPath.section == 2 {
            cell.textLabel?.text = privacy[indexPath.row]
        }

        cell.textLabel?.textColor = .label
        cell.textLabel?.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        cell.accessoryType = .disclosureIndicator
        cell.selectionStyle = .default

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        if indexPath.section == 0 && section0[indexPath.row].lowercased() == "health details" {
            let storyboard = UIStoryboard(name: "Home", bundle: nil)
            guard let vc = storyboard.instantiateViewController(withIdentifier: "HealthDetailsTableViewController") as? HealthDetailsTableViewController else {
                print("Unable to instantiate HealthDetailsTableViewController")
                return
            }
            navigationController?.pushViewController(vc, animated: true)
        }

        if indexPath.section == 1 {
            let vc = RemindersViewController(style: .insetGrouped)
            navigationController?.pushViewController(vc, animated: true)
        } else if indexPath.section == 2 {
            print("Selected privacy option: \(privacy[indexPath.row])")

        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 1:
            return "Features"
        case 2:
            return "Privacy"
        default:
            return nil
        }
    }

    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard section == 1 || section == 2,
              let header = view as? UITableViewHeaderFooterView else { return }

        header.textLabel?.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        header.textLabel?.textColor = .secondaryLabel
        header.textLabel?.text = header.textLabel?.text?.uppercased()
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch section {
        case 0:
            return 8
        case 1, 2:
            return 38
        default:
            return 8
        }
    }

    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.01
    }
}
