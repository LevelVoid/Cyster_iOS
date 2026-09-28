import UIKit
import FirebaseAuth

class ProfileTableViewController: UITableViewController {

    private let section0 = ["Health details"]
    private let features = ["Reminders"]
    private let dataBackup = ["Back Up Now", "Restore Backup"]
    private let privacy = ["Apps", "Devices"]
    
    private var lastBackupDate: Date?
    private var isBackingUp = false
    private var isRestoring = false

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
        loadBackupStatus()
        
        // Listen for backup status changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(backupStatusChanged),
            name: .backupStatusChanged,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateProfileName()
        loadBackupStatus()
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
        return 4
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return section0.count
        case 1:
            return features.count
        case 2:
            return dataBackup.count
        case 3:
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
            cell.accessoryType = .disclosureIndicator
        } else if indexPath.section == 2 {
            // Data & Backup section
            cell.textLabel?.text = dataBackup[indexPath.row]
            
            if indexPath.row == 0 {
                // Back Up Now row
                if isBackingUp {
                    cell.textLabel?.textColor = .secondaryLabel
                    let activityIndicator = UIActivityIndicatorView(style: .medium)
                    activityIndicator.startAnimating()
                    cell.accessoryView = activityIndicator
                } else {
                    cell.textLabel?.textColor = .systemBlue
                    cell.accessoryView = nil
                    cell.accessoryType = .none
                }
            } else if indexPath.row == 1 {
                // Restore Backup row
                if isRestoring {
                    cell.textLabel?.textColor = .secondaryLabel
                    let activityIndicator = UIActivityIndicatorView(style: .medium)
                    activityIndicator.startAnimating()
                    cell.accessoryView = activityIndicator
                } else {
                    cell.textLabel?.textColor = .systemBlue
                    cell.accessoryView = nil
                    cell.accessoryType = .none
                }
            }
        } else if indexPath.section == 3 {
            cell.textLabel?.text = privacy[indexPath.row]
            cell.textLabel?.textColor = .label
            cell.accessoryType = .disclosureIndicator
        }

        cell.textLabel?.font = UIFont.systemFont(ofSize: 17, weight: .regular)
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
            // Data & Backup section
            if indexPath.row == 0 {
                // Back Up Now
                handleBackupNow()
            } else if indexPath.row == 1 {
                // Restore Backup
                handleRestoreBackup()
            }
        } else if indexPath.section == 3 {
            print("Selected privacy option: \(privacy[indexPath.row])")
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 1:
            return "Features"
        case 2:
            return "Data & Backup"
        case 3:
            return "Privacy"
        default:
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == 2 {
            if let lastBackup = lastBackupDate {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                formatter.timeStyle = .short
                return "Last backup: \(formatter.string(from: lastBackup))"
            } else {
                return "No backup available"
            }
        }
        return nil
    }

    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard section == 1 || section == 2 || section == 3,
              let header = view as? UITableViewHeaderFooterView else { return }

        header.textLabel?.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        header.textLabel?.textColor = .secondaryLabel
        header.textLabel?.text = header.textLabel?.text?.uppercased()
    }
    
    override func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        guard section == 2,
              let footer = view as? UITableViewHeaderFooterView else { return }
        
        footer.textLabel?.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        footer.textLabel?.textColor = .secondaryLabel
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch section {
        case 0:
            return 8
        case 1, 2, 3:
            return 38
        default:
            return 8
        }
    }

    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section == 2 {
            return UITableView.automaticDimension
        }
        return 0.01
    }
    
    // MARK: - Backup Methods
    
    ///
    /// Loads the last backup date from Core Data.
    ///
    /// Parameters: None
    /// Returns: None
    /// Throws: None
    ///
    private func loadBackupStatus() {
        lastBackupDate = BackupManager.shared.getLastBackupDate()
        tableView.reloadSections(IndexSet(integer: 2), with: .none)
    }
    
    ///
    /// Handles the Back Up Now action.
    ///
    /// Parameters: None
    /// Returns: None
    /// Throws: None
    ///
    @MainActor
    private func handleBackupNow() {
        guard !isBackingUp else { return }
        
        // Confirm action
        let alert = UIAlertController(
            title: "Back Up Your Data",
            message: "This will backup all your health data, meals, symptoms, and cycle logs to the cloud.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Back Up Now", style: .default) { [weak self] _ in
            self?.performBackup()
        })
        
        present(alert, animated: true)
    }
    
    ///
    /// Performs the actual backup operation.
    ///
    /// Parameters: None
    /// Returns: None
    /// Throws: None
    ///
    @MainActor
    private func performBackup() {
        isBackingUp = true
        tableView.reloadRows(at: [IndexPath(row: 0, section: 2)], with: .none)
        
        Task {
            do {
                try await BackupManager.shared.createBackup()
                
                await MainActor.run {
                    isBackingUp = false
                    loadBackupStatus()
                    
                    let alert = UIAlertController(
                        title: "Backup Complete",
                        message: "Your data has been safely backed up to the cloud.",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    present(alert, animated: true)
                }
            } catch {
                await MainActor.run {
                    isBackingUp = false
                    tableView.reloadRows(at: [IndexPath(row: 0, section: 2)], with: .none)
                    
                    let alert = UIAlertController(
                        title: "Backup Failed",
                        message: error.localizedDescription,
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    present(alert, animated: true)
                }
            }
        }
    }
    
    ///
    /// Handles the Restore Backup action.
    ///
    /// Parameters: None
    /// Returns: None
    /// Throws: None
    ///
    @MainActor
    private func handleRestoreBackup() {
        guard !isRestoring else { return }
        
        // Check if backup exists first
        Task {
            do {
                let exists = try await BackupManager.shared.checkBackupExists()
                
                await MainActor.run {
                    if !exists {
                        let alert = UIAlertController(
                            title: "No Backup Found",
                            message: "You haven't created a backup yet. Back up your data first.",
                            preferredStyle: .alert
                        )
                        alert.addAction(UIAlertAction(title: "OK", style: .default))
                        present(alert, animated: true)
                        return
                    }
                    
                    // Confirm restore action
                    let alert = UIAlertController(
                        title: "Restore Backup",
                        message: "This will restore your data from your last backup. Your current data will be merged with the backup.",
                        preferredStyle: .alert
                    )
                    
                    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                    alert.addAction(UIAlertAction(title: "Restore", style: .default) { [weak self] _ in
                        self?.performRestore()
                    })
                    
                    present(alert, animated: true)
                }
            } catch {
                await MainActor.run {
                    let alert = UIAlertController(
                        title: "Error",
                        message: error.localizedDescription,
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    present(alert, animated: true)
                }
            }
        }
    }
    
    ///
    /// Performs the actual restore operation.
    ///
    /// Parameters: None
    /// Returns: None
    /// Throws: None
    ///
    @MainActor
    private func performRestore() {
        isRestoring = true
        tableView.reloadRows(at: [IndexPath(row: 1, section: 2)], with: .none)
        
        Task {
            do {
                try await BackupManager.shared.restoreBackup()
                
                await MainActor.run {
                    isRestoring = false
                    tableView.reloadRows(at: [IndexPath(row: 1, section: 2)], with: .none)
                    
                    let alert = UIAlertController(
                        title: "Restore Complete",
                        message: "Your data has been restored successfully. Please restart the app to see your restored data.",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    present(alert, animated: true)
                }
            } catch {
                await MainActor.run {
                    isRestoring = false
                    tableView.reloadRows(at: [IndexPath(row: 1, section: 2)], with: .none)
                    
                    let alert = UIAlertController(
                        title: "Restore Failed",
                        message: error.localizedDescription,
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    present(alert, animated: true)
                }
            }
        }
    }
    
    ///
    /// Called when backup status changes.
    ///
    /// Parameters: None
    /// Returns: None
    /// Throws: None
    ///
    @objc private func backupStatusChanged() {
        loadBackupStatus()
    }
}
