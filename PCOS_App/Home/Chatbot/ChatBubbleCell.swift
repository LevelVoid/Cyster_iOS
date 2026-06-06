import UIKit

final class ChatBubbleCell: UITableViewCell {

    static let identifier = "ChatBubbleCell"

    private let bubbleView   = UIView()
    private let messageLabel = UILabel()
    private let timeLabel    = UILabel()
    private let avatarView   = UIView()
    private let avatarLabel  = UILabel()

    private var bubbleLeadingToAvatar: NSLayoutConstraint!
    private var bubbleLeadingToEdge:   NSLayoutConstraint!
    private var bubbleTrailing:        NSLayoutConstraint!
    private var timeLabelLeading:      NSLayoutConstraint!
    private var timeLabelTrailing:     NSLayoutConstraint!

    static let userBubbleColor = UIColor(hex:"fe7a96")
    static let aiBubbleColor   = UIColor(hex:"ffffff")

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }

    private func setupViews() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        avatarView.backgroundColor = UIColor(hex:"fe7a96")
        avatarView.layer.cornerRadius = 14
        avatarView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(avatarView)

        avatarLabel.text = "A"
        avatarLabel.font = .systemFont(ofSize: 12, weight: .bold)
        avatarLabel.textColor = .white
        avatarLabel.textAlignment = .center
        avatarLabel.translatesAutoresizingMaskIntoConstraints = false
        avatarView.addSubview(avatarLabel)

        bubbleView.layer.cornerRadius = 18
        bubbleView.layer.cornerCurve = .continuous
        bubbleView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(bubbleView)

        messageLabel.numberOfLines = 0
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        bubbleView.addSubview(messageLabel)

        timeLabel.font = .systemFont(ofSize: 11)
        timeLabel.textColor = .secondaryLabel
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(timeLabel)

        NSLayoutConstraint.activate([
            avatarView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            avatarView.widthAnchor.constraint(equalToConstant: 28),
            avatarView.heightAnchor.constraint(equalToConstant: 28),
            avatarView.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor),
            avatarLabel.centerXAnchor.constraint(equalTo: avatarView.centerXAnchor),
            avatarLabel.centerYAnchor.constraint(equalTo: avatarView.centerYAnchor),
        ])

        NSLayoutConstraint.activate([
            bubbleView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            bubbleView.widthAnchor.constraint(lessThanOrEqualTo: contentView.widthAnchor, multiplier: 0.72),
        ])

        NSLayoutConstraint.activate([
            messageLabel.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 10),
            messageLabel.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -10),
            messageLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 14),
            messageLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -14),
        ])

        NSLayoutConstraint.activate([
            timeLabel.topAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: 3),
            timeLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
        ])

        bubbleLeadingToAvatar = bubbleView.leadingAnchor.constraint(
            equalTo: avatarView.trailingAnchor, constant: 6)
        bubbleLeadingToEdge = bubbleView.leadingAnchor.constraint(
            greaterThanOrEqualTo: contentView.leadingAnchor, constant: 60)
        bubbleTrailing = bubbleView.trailingAnchor.constraint(
            equalTo: contentView.trailingAnchor, constant: -16)
        timeLabelLeading = timeLabel.leadingAnchor.constraint(
            equalTo: avatarView.trailingAnchor, constant: 6)
        timeLabelTrailing = timeLabel.trailingAnchor.constraint(
            equalTo: contentView.trailingAnchor, constant: -16)
    }

    func configure(with message: ChatMessage) {
        let isUser = message.sender == .user

        messageLabel.attributedText = parseMarkdown(message.text, isUser: isUser)
        timeLabel.text = message.formattedTime

        bubbleLeadingToAvatar.isActive = false
        bubbleLeadingToEdge.isActive   = false
        bubbleTrailing.isActive        = false
        timeLabelLeading.isActive      = false
        timeLabelTrailing.isActive     = false

        if isUser {

            avatarView.isHidden = true

            bubbleLeadingToEdge.isActive = true   
            bubbleTrailing.isActive      = true   
            timeLabelTrailing.isActive   = true
            timeLabel.textAlignment      = .right

            bubbleView.backgroundColor = Self.userBubbleColor
            messageLabel.textColor = .white

            bubbleView.layer.maskedCorners = [
                .layerMinXMinYCorner,
                .layerMaxXMinYCorner,
                .layerMinXMaxYCorner
            ]

        } else {

            avatarView.isHidden = false

            bubbleLeadingToAvatar.isActive = true  
            timeLabelLeading.isActive      = true
            timeLabel.textAlignment        = .left

            bubbleView.backgroundColor = Self.aiBubbleColor
            messageLabel.textColor = .label

            bubbleView.layer.maskedCorners = [
                .layerMinXMinYCorner,
                .layerMaxXMinYCorner,
                .layerMaxXMaxYCorner
            ]
        }
    }

    private func parseMarkdown(_ text: String, isUser: Bool) -> NSAttributedString {
        let baseColor: UIColor = isUser ? .white : .label
        let baseFont = UIFont.systemFont(ofSize: 16)
        let boldFont = UIFont.systemFont(ofSize: 16, weight: .semibold)

        var cleanText = text

        cleanText = cleanText.replacingOccurrences(of: "\u{FFFD}", with: "")
        cleanText = String(cleanText.unicodeScalars.filter { !$0.properties.isEmojiPresentation })

        let listPattern = "(?m)^[\\*\\-]\\s+"
        if let regex = try? NSRegularExpression(pattern: listPattern) {
            cleanText = regex.stringByReplacingMatches(
                in: cleanText,
                range: NSRange(cleanText.startIndex..., in: cleanText),
                withTemplate: "• "
            )
        }

        if let regex = try? NSRegularExpression(pattern: "\\n{3,}") {
            cleanText = regex.stringByReplacingMatches(
                in: cleanText,
                range: NSRange(cleanText.startIndex..., in: cleanText),
                withTemplate: "\n\n"
            )
        }

        let result = NSMutableAttributedString()
        let lines  = cleanText.components(separatedBy: "\n")

        for (i, line) in lines.enumerated() {
            result.append(processInlineBold(line, baseFont: baseFont, boldFont: boldFont, color: baseColor))
            if i < lines.count - 1 {
                result.append(NSAttributedString(
                    string: "\n",
                    attributes: [.font: baseFont, .foregroundColor: baseColor]
                ))
            }
        }
        return result
    }

    private func processInlineBold(
        _ text: String,
        baseFont: UIFont,
        boldFont: UIFont,
        color: UIColor
    ) -> NSAttributedString {
        let result  = NSMutableAttributedString()
        let pattern = "\\*\\*(.+?)\\*\\*"
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return NSAttributedString(string: text,
                attributes: [.font: baseFont, .foregroundColor: color])
        }

        var lastIndex = text.startIndex
        let matches   = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))

        for match in matches {
            let preRange = lastIndex..<text.index(text.startIndex, offsetBy: match.range.location)
            if !preRange.isEmpty {
                result.append(NSAttributedString(string: String(text[preRange]),
                    attributes: [.font: baseFont, .foregroundColor: color]))
            }
            if let boldRange = Range(match.range(at: 1), in: text) {
                result.append(NSAttributedString(string: String(text[boldRange]),
                    attributes: [.font: boldFont, .foregroundColor: color]))
            }
            lastIndex = text.index(text.startIndex, offsetBy: match.range.upperBound)
        }

        if lastIndex < text.endIndex {
            result.append(NSAttributedString(string: String(text[lastIndex...]),
                attributes: [.font: baseFont, .foregroundColor: color]))
        }
        return result
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        bubbleLeadingToAvatar.isActive = false
        bubbleLeadingToEdge.isActive   = false
        bubbleTrailing.isActive        = false
        timeLabelLeading.isActive      = false
        timeLabelTrailing.isActive     = false
        messageLabel.attributedText    = nil
        avatarView.isHidden            = false
    }
}
