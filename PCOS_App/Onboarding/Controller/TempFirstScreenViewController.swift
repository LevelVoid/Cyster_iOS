import UIKit

class TempFirstScreenViewController: UIViewController {

    @IBOutlet weak var appleButton: UIButton!
    @IBOutlet weak var googleButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        styleAuthButton(appleButton, title: "Continue with Apple", sfSymbol: "apple.logo", assetName: nil)
        styleAuthButton(googleButton, title: "Continue with Google", sfSymbol: nil, assetName: "google")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    // MARK: - Styling

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
                // Resize the image to 20x20 to prevent it from blowing up the button size
                let targetSize = CGSize(width: 20, height: 20)
                let renderer = UIGraphicsImageRenderer(size: targetSize)
                let resizedImage = renderer.image { _ in
                    originalImage.draw(in: CGRect(origin: .zero, size: targetSize))
                }
                // Ensure the image keeps its original colors (don't tint it like a symbol)
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
        button.tintColor = titleColor // Fallback to ensure no blue tint
    }
}
