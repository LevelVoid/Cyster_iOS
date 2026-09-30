import UIKit

// MARK: - LegalDocument

/// Identifies which legal document to display.
enum LegalDocument {
    case termsOfService
    case privacyPolicy

    var title: String {
        switch self {
        case .termsOfService: return "Terms of Service"
        case .privacyPolicy:  return "Privacy Policy"
        }
    }

    var content: String {
        switch self {
        case .termsOfService: return LegalContent.termsOfService
        case .privacyPolicy:  return LegalContent.privacyPolicy
        }
    }
}

// MARK: - LegalDocumentViewController

/// Reusable native UIKit screen for displaying Terms of Service and Privacy Policy.
///
/// Usage:
/// ```swift
/// let vc = LegalDocumentViewController(document: .termsOfService)
/// navigationController?.pushViewController(vc, animated: true)
/// ```
///
/// This controller relies on the existing navigation stack for Back navigation.
/// Do NOT wrap it in a second UINavigationController unless presenting modally
/// from a context that has no navigation controller.
final class LegalDocumentViewController: UIViewController {

    // MARK: - Properties

    private let document: LegalDocument

    // MARK: - UI

    private lazy var scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.alwaysBounceVertical = true
        return sv
    }()

    private lazy var contentView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private lazy var textView: UITextView = {
        let tv = UITextView()
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.isEditable = false
        tv.isScrollEnabled = false          // Scroll is handled by the outer UIScrollView
        tv.isSelectable = true
        tv.dataDetectorTypes = [.link]
        tv.backgroundColor = .clear
        tv.textContainerInset = .zero
        tv.textContainer.lineFragmentPadding = 0
        return tv
    }()

    // MARK: - Init

    init(document: LegalDocument) {
        self.document = document
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("Use init(document:)")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = document.title
        view.backgroundColor = .systemBackground

        // The navigation controller provides the back button automatically when
        // this controller is pushed. Do NOT add a custom close button here.
        setupLayout()
        applyContent()
    }

    // MARK: - Setup

    private func setupLayout() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(textView)

        NSLayoutConstraint.activate([
            // ScrollView fills the safe area
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // ContentView matches scroll view width
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            // TextView with horizontal padding
            textView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
            textView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            textView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            textView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -32)
        ])
    }

    private func applyContent() {
        textView.attributedText = buildAttributedContent()
    }

    // MARK: - Attributed Content Builder

    private func buildAttributedContent() -> NSAttributedString {
        let output = NSMutableAttributedString()

        // Document title
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 26, weight: .bold),
            .foregroundColor: UIColor.label
        ]
        output.append(NSAttributedString(string: document.title + "\n\n", attributes: titleAttrs))

        // Last updated line
        let subtitleAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14, weight: .regular),
            .foregroundColor: UIColor.secondaryLabel
        ]
        output.append(NSAttributedString(string: "Last updated: September 2026\n\n", attributes: subtitleAttrs))

        // Body text — parsed from the plain-text legal content
        let bodyAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 16, weight: .regular),
            .foregroundColor: UIColor.label
        ]
        let headingAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold),
            .foregroundColor: UIColor.label
        ]

        let lines = document.content.components(separatedBy: "\n")
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            // Lines starting with a number+period are section headings
            if let _ = trimmed.range(of: #"^\d+\."#, options: .regularExpression) {
                output.append(NSAttributedString(string: "\n" + trimmed + "\n\n", attributes: headingAttrs))
            } else {
                output.append(NSAttributedString(string: trimmed + "\n", attributes: bodyAttrs))
            }
        }

        return output
    }
}

// MARK: - LegalContent

/// Static legal document text.
///
/// The exact wording here is illustrative. Your legal counsel should review
/// and approve the final text — in particular the health/AI data sections.
private enum LegalContent {

    static let termsOfService = """
    1. Introduction
    Welcome to Cyster, a health and wellness app designed to help users understand and manage PCOS (Polycystic Ovary Syndrome). By downloading, installing, or using Cyster ("the App"), you agree to be bound by these Terms of Service ("Terms"). Please read them carefully. If you do not agree to these Terms, do not use the App.

    2. Eligibility
    You must be at least 13 years old to use Cyster. If you are under 18, you must have your parent or guardian's permission. By using the App, you represent and warrant that you meet these requirements.

    3. Account Registration
    To access certain features, you must create an account using Apple Sign-In or Google Sign-In. You are responsible for maintaining the confidentiality of your account credentials and for all activity that occurs under your account. You must notify us immediately of any unauthorised use of your account.

    4. Use of Cyster
    You may use Cyster solely for your personal, non-commercial health and wellness purposes. You agree not to misuse the App in any way, including but not limited to attempting to access non-public areas, interfering with the App's operation, or using the App for any unlawful purpose.

    5. AI-Generated Information
    Cyster uses artificial intelligence to provide personalised health insights, recommendations, and content. This AI-generated information is provided for informational and educational purposes only. It is not a substitute for professional medical advice, diagnosis, or treatment. Always seek the advice of a qualified healthcare provider with any questions you may have regarding a medical condition.

    6. Health and Wellness Disclaimer
    Cyster is a wellness application and is not a medical device or healthcare provider. The information provided in the App, including symptom tracking, cycle analysis, diet and exercise recommendations, and AI insights, is for general wellness purposes only and does not constitute medical advice. We strongly encourage you to consult a licensed medical professional for any health concerns.

    7. Subscriptions and Purchases
    Cyster offers optional paid subscription plans ("Premium") that unlock additional features. Subscriptions are processed through Apple's App Store or Google Play and are subject to their respective terms and billing policies. Prices and plans may change at any time, with reasonable notice provided where required by law.

    8. Free Trials
    We may offer free trial periods for our Premium subscription. At the end of the trial period, your subscription will automatically convert to a paid plan unless you cancel before the trial ends. Cancellation must be done through your Apple or Google account settings.

    9. Cancellation and Refunds
    You may cancel your subscription at any time through your Apple or Google account settings. Cancellation takes effect at the end of the current billing period. Refunds are governed by Apple's or Google's refund policies. We do not issue independent refunds for partial subscription periods.

    10. User Content and Data
    You retain ownership of any health data and content you enter into Cyster. By using the App, you grant Cyster a limited, non-exclusive licence to process your data solely for the purpose of providing and improving the App's services, as described in our Privacy Policy.

    11. Intellectual Property
    Cyster and its original content, features, and functionality are owned by the Cyster team and are protected by applicable intellectual property laws. You may not copy, modify, distribute, sell, or lease any part of the App without our prior written consent.

    12. Prohibited Use
    You agree not to:
    - Use the App for any purpose that is unlawful or prohibited by these Terms.
    - Attempt to gain unauthorised access to any part of the App or its infrastructure.
    - Transmit any harmful, offensive, or disruptive content.
    - Reverse engineer, decompile, or disassemble any part of the App.
    - Use the App to compete with Cyster's business.

    13. Service Availability
    We strive to keep Cyster available at all times, but we do not guarantee uninterrupted access. The App may be unavailable due to maintenance, technical issues, or circumstances beyond our control. We reserve the right to modify or discontinue the App (or any part of it) at any time.

    14. Limitation of Liability
    To the fullest extent permitted by applicable law, Cyster and its team shall not be liable for any indirect, incidental, special, consequential, or punitive damages arising from your use of, or inability to use, the App. Our total liability for any claim arising under these Terms shall not exceed the amount you paid us in the twelve months preceding the claim.

    15. Changes to the Terms
    We may update these Terms from time to time. We will notify you of material changes by posting the new Terms within the App and updating the "Last updated" date. Your continued use of the App after such changes constitutes your acceptance of the revised Terms.

    16. Contact Information
    If you have any questions about these Terms, please contact us:
    Email: support@cysterapp.com
    """

    static let privacyPolicy = """
    1. Introduction
    Cyster ("we", "us", or "our") is committed to protecting your personal information. This Privacy Policy explains how we collect, use, store, and share information when you use the Cyster app. By using the App, you agree to the practices described in this Privacy Policy.

    2. Information We Collect
    We collect information in the following ways: information you provide directly, information collected automatically through your use of the App, and information from third-party services you connect to the App.

    3. Information You Provide
    When you use Cyster, you may provide:
    - Account information (name, email address, profile photo) via Apple Sign-In or Google Sign-In.
    - Health and wellness data, including menstrual cycle dates, symptoms, weight, height, diet type, and exercise habits.
    - PCOS phenotype information.
    - Chatbot interactions and queries submitted to the AI assistant.
    - Reminders and preferences you configure in the App.

    4. Health and Wellness Data
    We treat health and wellness data as sensitive information. This data is stored securely in our cloud infrastructure (Firebase/Firestore) and is associated only with your authenticated account. We do not sell your health data to third parties. Health data is used solely to provide and improve the App's personalised features.

    5. How We Use Information
    We use the information we collect to:
    - Provide, maintain, and improve the App's features and services.
    - Generate personalised health insights and recommendations.
    - Respond to your support requests.
    - Send relevant notifications and reminders you have opted into.
    - Comply with legal obligations.
    - Detect and prevent fraud or abuse.

    6. AI Processing
    Cyster uses AI models to analyse your health data and generate personalised recommendations, cycle insights, diet advice, and chatbot responses. AI processing may involve sending anonymised or pseudonymised data to cloud AI services. We do not share personally identifiable information with AI providers beyond what is strictly necessary to deliver the service.

    7. Third-Party Services
    Cyster integrates with the following third-party services, which have their own privacy policies:
    - Firebase / Google (authentication, database, analytics): policies.google.com/privacy
    - RevenueCat (subscription management): www.revenuecat.com/privacy
    - Apple (Sign-In, App Store): www.apple.com/legal/privacy

    We recommend reviewing the privacy policies of these providers.

    8. Data Storage
    Your data is stored on Firebase / Firestore servers. Data may be stored and processed in countries outside your own. We take appropriate technical and organisational measures to ensure your data is protected wherever it is stored.

    9. Data Retention
    We retain your personal data for as long as your account is active or as needed to provide services. If you delete your account, we will delete your personal data within 30 days, except where we are required by law to retain it for a longer period.

    10. Data Security
    We implement industry-standard security measures, including encryption in transit (TLS) and at rest, to protect your personal data. However, no method of transmission over the internet or electronic storage is 100% secure, and we cannot guarantee absolute security.

    11. Data Deletion
    You can request deletion of your account and all associated data directly within the App via Settings → Delete Account. This action is permanent and cannot be undone. We will process your deletion request within 30 days.

    12. Your Rights
    Depending on your location, you may have the following rights regarding your personal data:
    - Right of access: You can request a copy of your personal data.
    - Right to rectification: You can request correction of inaccurate data.
    - Right to erasure: You can request deletion of your data (see Section 11).
    - Right to data portability: You can request your data in a machine-readable format.
    - Right to object: You can object to certain types of processing.
    To exercise any of these rights, contact us at support@cysterapp.com.

    13. Children's Privacy
    Cyster is not intended for children under 13. We do not knowingly collect personal information from children under 13. If we become aware that we have inadvertently collected such information, we will take steps to delete it promptly.

    14. Changes to This Privacy Policy
    We may update this Privacy Policy from time to time. We will notify you of material changes by posting the updated policy within the App and updating the "Last updated" date. Your continued use of the App after such changes constitutes your acceptance of the revised Privacy Policy.

    15. Contact Information
    If you have any questions or concerns about this Privacy Policy or our data practices, please contact us:
    Email: support@cysterapp.com
    """
}
