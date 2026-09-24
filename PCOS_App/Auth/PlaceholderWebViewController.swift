import UIKit
import WebKit

// MARK: - PlaceholderWebViewController

/// Lightweight WKWebView screen for Terms of Service and Privacy Policy links.
/// Milestone 1 shows these as tappable placeholders; real URLs can be wired later.
final class PlaceholderWebViewController: UIViewController {

    // MARK: Properties

    var pageTitle: String = "Legal"
    var urlString: String = "about:blank"

    // MARK: UI

    private lazy var webView: WKWebView = {
        let wv = WKWebView()
        wv.translatesAutoresizingMaskIntoConstraints = false
        return wv
    }()

    private lazy var activityIndicator: UIActivityIndicatorView = {
        let ai = UIActivityIndicatorView(style: .medium)
        ai.translatesAutoresizingMaskIntoConstraints = false
        ai.hidesWhenStopped = true
        return ai
    }()

    // MARK: Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = pageTitle
        view.backgroundColor = .systemBackground

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(closeTapped)
        )

        setupUI()
        loadContent()
    }

    // MARK: - Setup

    private func setupUI() {
        view.addSubview(webView)
        view.addSubview(activityIndicator)

        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])

        webView.navigationDelegate = self
    }

    private func loadContent() {
        activityIndicator.startAnimating()
        if let url = URL(string: urlString), !urlString.isEmpty, urlString != "about:blank" {
            webView.load(URLRequest(url: url))
        } else {
            // Placeholder HTML when no real URL is set yet
            let placeholderHTML = """
            <html>
            <head>
            <meta name="viewport" content="width=device-width, initial-scale=1">
            <style>
                body { font-family: -apple-system, sans-serif; padding: 24px; color: #333; }
                h2  { font-size: 22px; margin-bottom: 12px; }
                p   { line-height: 1.6; color: #666; }
            </style>
            </head>
            <body>
            <h2>\(pageTitle)</h2>
            <p>This page will contain the full \(pageTitle) document. Check back soon.</p>
            </body>
            </html>
            """
            webView.loadHTMLString(placeholderHTML, baseURL: nil)
        }
    }

    // MARK: - Actions

    @objc private func closeTapped() {
        dismiss(animated: true)
    }
}

// MARK: - WKNavigationDelegate

extension PlaceholderWebViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        activityIndicator.stopAnimating()
    }
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        activityIndicator.stopAnimating()
    }
}
