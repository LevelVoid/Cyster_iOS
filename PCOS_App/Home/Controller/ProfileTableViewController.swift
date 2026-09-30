import UIKit
import FirebaseAuth

class ProfileTableViewController: UITableViewController {

    private let section0 = ["Health details"]
    private let features = ["Reminders"]
    private let dataBackup = ["Back Up Now", "Restore Backup"]
    private let legal = ["Terms of Service", "Privacy Policy"]
    
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
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "SubtitleCell")
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
        return 5
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
            return legal.count
        case 4:
            return 1  // Delete Account
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
            cell.textLabel?.textColor = .label
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
            // Legal section
            cell.textLabel?.text = legal[indexPath.row]
            cell.textLabel?.textColor = .label
            cell.accessoryType = .disclosureIndicator
        } else if indexPath.section == 4 {
            // Delete Account section - need subtitle style
            let deleteCell = UITableViewCell(style: .subtitle, reuseIdentifier: "SubtitleCell")
            deleteCell.textLabel?.text = "Delete Account"
            deleteCell.textLabel?.textColor = .systemRed
            deleteCell.textLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)

            // Add trash icon
            let trashImage = UIImage(systemName: "trash")?
                .withTintColor(.systemRed, renderingMode: .alwaysOriginal)
            deleteCell.accessoryView = UIImageView(image: trashImage)
            deleteCell.selectionStyle = .default

            return deleteCell
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
        } else if indexPath.section == 1 {
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
            // Legal section
            handleLegalSelection(indexPath.row)
        } else if indexPath.section == 4 {
            // Delete Account
            handleDeleteAccount()
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 1:
            return "Features"
        case 2:
            return "Data & Backup"
        case 3:
            return "Legal"
        case 4:
            return "Account"
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
        guard section >= 1 && section <= 4,
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
        case 1, 2, 3, 4:
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
    /// Loads the last backup date from BackupEngine.
    ///
    /// Parameters: None
    /// Returns: None
    /// Throws: None
    ///
    private func loadBackupStatus() {
        lastBackupDate = BackupEngine.shared.getLastBackupDate()
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
    /// Performs the actual backup operation using BackupEngine.
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
                try await BackupEngine.shared.forceUpload()

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
    /// Handles the Restore Backup action using RestoreManager.
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
                let exists = try await RestoreManager.shared.checkBackupExists()

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
    /// Performs the actual restore operation using RestoreManager.
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
                _ = try await RestoreManager.shared.restoreIfAvailable()

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

    // MARK: - Legal Methods

    ///
    /// Handles selection of a legal row (Privacy Policy or Terms of Service).
    ///
    /// Parameters:
    ///   - row: The row index in the legal section
    /// Returns: None
    /// Throws: None
    ///
    /// Why this exists:
    /// Presents placeholder screens for legal documents per Milestone 8A spec.
    ///
    private func handleLegalSelection(_ row: Int) {
        let document: LegalDocument = (row == 0) ? .termsOfService : .privacyPolicy
        let vc = LegalDocumentViewController(document: document)
        // Settings is inside a UINavigationController, so push gives us the
        // automatic Back button — no custom close button needed.
        navigationController?.pushViewController(vc, animated: true)
    }

    // MARK: - Account Deletion Methods

    ///
    /// Handles the Delete Account action with two-step confirmation.
    ///
    /// Parameters: None
    /// Returns: None
    /// Throws: None
    ///
    /// Why this exists:
    /// Entry point for account deletion flow per Milestone 8A spec.
    /// Shows two confirmations before triggering AccountDeletionManager.
    ///
    private func handleDeleteAccount() {
        // First confirmation sheet
        let firstAlert = UIAlertController(
            title: "Delete Account",
            message: """
            This permanently deletes:
            • your Cyster account
            • all cloud backups
            • all local health data
            • your synced profile

            This cannot be undone.
            """,
            preferredStyle: .actionSheet
        )

        firstAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        firstAlert.addAction(UIAlertAction(title: "Continue", style: .destructive) { [weak self] _ in
            self?.showFinalDeleteConfirmation()
        })

        // For iPad support
        if let popover = firstAlert.popoverPresentationController {
            popover.sourceView = self.view
            popover.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }

        present(firstAlert, animated: true)
    }

    ///
    /// Shows the final destructive confirmation before deletion.
    ///
    /// Parameters: None
    /// Returns: None
    /// Throws: None
    ///
    private func showFinalDeleteConfirmation() {
        let finalAlert = UIAlertController(
            title: "Delete Permanently?",
            message: nil,
            preferredStyle: .alert
        )

        finalAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        finalAlert.addAction(UIAlertAction(title: "Delete Account", style: .destructive) { [weak self] _ in
            self?.performAccountDeletion()
        })

        present(finalAlert, animated: true)
    }

    ///
    /// Performs the actual account deletion using AccountDeletionManager.
    ///
    /// Parameters: None
    /// Returns: None
    /// Throws: None
    ///
    @MainActor
    private func performAccountDeletion() {
        // Show loading indicator
        let loadingAlert = UIAlertController(
            title: "Deleting Account",
            message: "Please wait while we delete your account and all data...",
            preferredStyle: .alert
        )

        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.startAnimating()
        loadingAlert.view.addSubview(indicator)

        NSLayoutConstraint.activate([
            indicator.centerXAnchor.constraint(equalTo: loadingAlert.view.centerXAnchor),
            indicator.bottomAnchor.constraint(equalTo: loadingAlert.view.bottomAnchor, constant: -20)
        ])

        present(loadingAlert, animated: true)

        Task {
            do {
                print("🗑 Starting account deletion...")
                try await AccountDeletionManager.shared.deleteAccount(from: self)

                // Dismiss loading (if still visible)
                await MainActor.run {
                    loadingAlert.dismiss(animated: true)
                    print("✅ Account deletion completed successfully")
                }
            } catch {
                // Dismiss loading and show error
                await MainActor.run {
                    loadingAlert.dismiss(animated: true) { [weak self] in
                        print("❌ Account deletion failed: \(error.localizedDescription)")

                        let errorAlert = UIAlertController(
                            title: "Deletion Failed",
                            message: error.localizedDescription,
                            preferredStyle: .alert
                        )
                        errorAlert.addAction(UIAlertAction(title: "OK", style: .default))
                        self?.present(errorAlert, animated: true)
                    }
                }
            }
        }
    }
}
