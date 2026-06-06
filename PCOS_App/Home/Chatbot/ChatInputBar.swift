import UIKit

protocol ChatInputBarDelegate: AnyObject {
    func inputBar(_ bar: ChatInputBar, didSend text: String)
}

final class ChatInputBar: UIView {

    weak var delegate: ChatInputBarDelegate?

    private let containerView = UIView()
    let textView = UITextView()
    private let sendButton = UIButton(type: .system)
    private let placeholderLabel = UILabel()

    private var textViewHeightConstraint: NSLayoutConstraint!
    private let minHeight: CGFloat = 36
    private let maxHeight: CGFloat = 100

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }

    override var intrinsicContentSize: CGSize {
        return .zero
    }

    private func setupViews() {
        autoresizingMask = .flexibleHeight
        backgroundColor = UIColor.systemBackground

        let border = UIView()
        border.backgroundColor = UIColor.separator
        border.translatesAutoresizingMaskIntoConstraints = false
        addSubview(border)
        NSLayoutConstraint.activate([
            border.topAnchor.constraint(equalTo: topAnchor),
            border.leadingAnchor.constraint(equalTo: leadingAnchor),
            border.trailingAnchor.constraint(equalTo: trailingAnchor),
            border.heightAnchor.constraint(equalToConstant: 0.5)
        ])

        containerView.layer.cornerRadius = 18
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = UIColor.systemGray4.cgColor
        containerView.clipsToBounds = true
        containerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(containerView)

        textView.font = .systemFont(ofSize: 16)
        textView.backgroundColor = .clear
        textView.isScrollEnabled = false
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 4, bottom: 8, right: 4)
        textView.delegate = self
        textView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(textView)

        placeholderLabel.text = "Message Cyster..."
        placeholderLabel.font = .systemFont(ofSize: 16)
        placeholderLabel.textColor = .placeholderText
        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(placeholderLabel)

        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
        let img = UIImage(systemName: "arrow.up", withConfiguration: config)
        sendButton.setImage(img, for: .normal)
        sendButton.backgroundColor = UIColor(hex:"fe7a96") 
        sendButton.tintColor = .white
        sendButton.layer.cornerRadius = 16
        sendButton.isEnabled = false
        sendButton.alpha = 0.4
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        sendButton.addTarget(self, action: #selector(sendTapped), for: .touchUpInside)
        addSubview(sendButton)

        textViewHeightConstraint = textView.heightAnchor.constraint(equalToConstant: minHeight)

        NSLayoutConstraint.activate([

            containerView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            containerView.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -8),
            containerView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -8),

            textView.topAnchor.constraint(equalTo: containerView.topAnchor),
            textView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
            textView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            textView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            textViewHeightConstraint,

            placeholderLabel.leadingAnchor.constraint(equalTo: textView.leadingAnchor, constant: 12),
            placeholderLabel.centerYAnchor.constraint(equalTo: textView.centerYAnchor),

            sendButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            sendButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            sendButton.widthAnchor.constraint(equalToConstant: 32),
            sendButton.heightAnchor.constraint(equalToConstant: 32)
        ])
    }

    @objc private func sendTapped() {
        let text = textView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        delegate?.inputBar(self, didSend: text)
        textView.text = ""
        updateSendButton()
        updateHeight()
        placeholderLabel.isHidden = false
    }

    private func updateSendButton() {
        let hasText = !(textView.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
        sendButton.isEnabled = hasText
        UIView.animate(withDuration: 0.15) {
            self.sendButton.alpha = hasText ? 1.0 : 0.4
        }
    }

    private func updateHeight() {
        let size = textView.sizeThatFits(CGSize(width: textView.frame.width, height: .infinity))
        let newHeight = min(max(size.height, minHeight), maxHeight)
        textView.isScrollEnabled = size.height > maxHeight
        if textViewHeightConstraint.constant != newHeight {
            textViewHeightConstraint.constant = newHeight
            invalidateIntrinsicContentSize()
        }
    }
}

extension ChatInputBar: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        placeholderLabel.isHidden = !textView.text.isEmpty
        updateSendButton()
        updateHeight()
    }
}
