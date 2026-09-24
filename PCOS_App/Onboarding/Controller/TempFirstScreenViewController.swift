import UIKit

class TempFirstScreenViewController: UIViewController {

    // MARK: - IBOutlets (storyboard)

    @IBOutlet weak var appleButton: UIButton!
    @IBOutlet weak var googleButton: UIButton!
    /// The "By continuing, you agree to…" label — made tappable for ToS / Privacy
    @IBOutlet weak var legalLabel: UILabel!

    // MARK: - Loading overlay (programmatic only — not in storyboard)

    private lazy var loadingOverlay: UIView = {
        let overlay = UIView()
        overlay.backgroundColor = UIColor.black.withAlphaComponent(0.35)
        overlay.translatesAutoresizingMaskIntoConstraints = false
        overlay.isHidden = true

        let spinner = UIActivityIndicatorView(style: .large)
        spinner.color = .white
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.startAnimating()
        overlay.addSubview(spinner)
        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: overlay.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: overlay.centerYAnchor)
        ])
        return overlay
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        styleAuthButton(appleButton, title: "Continue with Apple", sfSymbol: "apple.logo", assetName: nil)
        styleAuthButton(googleButton, title: "Continue with Google", sfSymbol: nil, assetName: "google")

        setupLoadingOverlay()
        setupLegalLabelTap()

        AuthManager.shared.delegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    // MARK: - Setup

    private func setupLoadingOverlay() {
        view.addSubview(loadingOverlay)
        NSLayoutConstraint.activate([
            loadingOverlay.topAnchor.constraint(equalTo: view.topAnchor),
            loadingOverlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            loadingOverlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            loadingOverlay.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupLegalLabelTap() {
        guard let legalLabel = legalLabel else { return }
        legalLabel.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(legalLabelTapped(_:)))
        legalLabel.addGestureRecognizer(tap)
    }

    // MARK: - IBActions

    @IBAction func appleButtonTapped(_ sender: UIButton) {
        setLoading(true)
        AuthManager.shared.signInWithApple(from: self)
    }

    @IBAction func googleButtonTapped(_ sender: UIButton) {
        setLoading(true)
        AuthManager.shared.signInWithGoogle(from: self)
    }

    // MARK: - Legal label tap

    @objc private func legalLabelTapped(_ gesture: UITapGestureRecognizer) {
        guard let label = gesture.view as? UILabel,
              let text = label.text else { return }

        // Detect which word was tapped
        let tosRange = (text as NSString).range(of: "Terms")
        let privacyRange = (text as NSString).range(of: "Privacy Policy")

        let tapPoint = gesture.location(in: label)
        let index = characterIndex(at: tapPoint, in: label)

        if NSLocationInRange(index, tosRange) {
            presentPlaceholder(title: "Terms of Service")
        } else if NSLocationInRange(index, privacyRange) {
            presentPlaceholder(title: "Privacy Policy")
        } else {
            // Tapped anywhere on label — open ToS as default
            presentPlaceholder(title: "Terms of Service")
        }
    }

    private func characterIndex(at point: CGPoint, in label: UILabel) -> Int {
        guard let attributedText = label.attributedText else {
            // Fallback: approximate by horizontal position
            let fraction = point.x / label.bounds.width
            return Int(fraction * CGFloat(label.text?.count ?? 0))
        }
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: label.bounds.size)
        let textStorage = NSTextStorage(attributedString: attributedText)

        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)
        textContainer.lineFragmentPadding = 0
        textContainer.maximumNumberOfLines = label.numberOfLines
        textContainer.lineBreakMode = label.lineBreakMode

        return layoutManager.characterIndex(
            for: point,
            in: textContainer,
            fractionOfDistanceBetweenInsertionPoints: nil
        )
    }

    private func presentPlaceholder(title: String) {
        let vc = PlaceholderWebViewController()
        vc.pageTitle = title
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .pageSheet
        present(nav, animated: true)
    }

    // MARK: - Loading State

    private func setLoading(_ isLoading: Bool) {
        loadingOverlay.isHidden = !isLoading
        appleButton.isEnabled = !isLoading
        googleButton.isEnabled = !isLoading
    }

    // MARK: - Button Styling

    private func styleAuthButton(_ button: UIButton, title: String, sfSymbol: String?, assetName: String?) {
        var config = UIButton.Configuration.plain()
        config.title = title

        let titleColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1)
        let font = UIFont.systemFont(ofSize: 17, weight: .medium)

        config.baseForegroundColor = titleColor
        config.imagePadding = 8

        if let symbolName = sfSymbol {
            let symbolConfig = UIImage.SymbolConfiguration(pointSize: 17, weight: .medium)
            config.image = UIImage(systemName: symbolName, withConfiguration: symbolConfig)
        } else if let assetName = assetName {
            if let originalImage = UIImage(named: assetName) {
                let targetSize = CGSize(width: 20, height: 20)
                let renderer = UIGraphicsImageRenderer(size: targetSize)
                let resizedImage = renderer.image { _ in
                    originalImage.draw(in: CGRect(origin: .zero, size: targetSize))
                }
                config.image = resizedImage.withRenderingMode(.alwaysOriginal)
            }
        }

        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attrs in
            var updated = attrs
            updated.font = font
            return updated
        }

        config.background.cornerRadius = 27
        config.background.strokeColor = .systemGray3
        config.background.strokeWidth = 1.5
        config.background.backgroundColor = .systemBackground

        button.configuration = config
        button.clipsToBounds = true
        button.tintColor = titleColor
    }
}

// MARK: - AuthManagerDelegate

extension TempFirstScreenViewController: AuthManagerDelegate {

    func authManagerDidAuthenticate(result: AuthResult) {
        setLoading(false)
        LaunchCoordinator.shared.handleSuccessfulAuth(from: self)
    }

    func authManagerDidFail(error: Error) {
        setLoading(false)
        let alert = UIAlertController(
            title: "Sign In Failed",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
