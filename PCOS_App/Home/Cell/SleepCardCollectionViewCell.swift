//
//  SleepCardCollectionViewCell.swift
//  PCOS_App
//
//  Created by SDC-USER on 04/02/26.
//

import UIKit

class SleepCardCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var Card: UIView!

    // MARK: - Programmatic Labels
    // These labels are added in code so no storyboard wiring is needed.
    private var durationLabel: UILabel!
    private var qualityLabel: UILabel!
    private var subtitleLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        Card.layer.cornerRadius = 20
        setupProgrammaticLabels()
    }

    // MARK: - Setup

    private func setupProgrammaticLabels() {
        // Duration (large, bold)
        durationLabel = UILabel()
        durationLabel.font = .systemFont(ofSize: 32, weight: .bold)
        durationLabel.textColor = .label
        durationLabel.textAlignment = .center
        durationLabel.translatesAutoresizingMaskIntoConstraints = false
        Card.addSubview(durationLabel)

        // Quality (medium, coloured)
        qualityLabel = UILabel()
        qualityLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        qualityLabel.textAlignment = .center
        qualityLabel.translatesAutoresizingMaskIntoConstraints = false
        Card.addSubview(qualityLabel)

        // Subtitle / tip
        subtitleLabel = UILabel()
        subtitleLabel.font = .systemFont(ofSize: 12, weight: .regular)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        Card.addSubview(subtitleLabel)

        NSLayoutConstraint.activate([
            durationLabel.centerXAnchor.constraint(equalTo: Card.centerXAnchor),
            durationLabel.centerYAnchor.constraint(equalTo: Card.centerYAnchor, constant: -22),

            qualityLabel.centerXAnchor.constraint(equalTo: Card.centerXAnchor),
            qualityLabel.topAnchor.constraint(equalTo: durationLabel.bottomAnchor, constant: 4),

            subtitleLabel.centerXAnchor.constraint(equalTo: Card.centerXAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: qualityLabel.bottomAnchor, constant: 6),
            subtitleLabel.leadingAnchor.constraint(equalTo: Card.leadingAnchor, constant: 14),
            subtitleLabel.trailingAnchor.constraint(equalTo: Card.trailingAnchor, constant: -14)
        ])
    }

    // MARK: - Configure

    func configure(with sleepData: SleepData?) {
        if let data = sleepData {
            durationLabel.text = data.formattedDuration
            qualityLabel.text  = "\(data.quality.emoji) \(data.quality.label) sleep"
            qualityLabel.textColor = qualityColor(data.quality)
            subtitleLabel.text = tipText(for: data.quality)
        } else {
            // No HealthKit data — show motivational fallback
            durationLabel.text = "– –"
            qualityLabel.text  = "No data yet"
            qualityLabel.textColor = .secondaryLabel
            subtitleLabel.text = "Connect the Health app and sleep with your Apple Watch to track sleep patterns."
        }
    }

    // MARK: - Helpers

    private func qualityColor(_ quality: SleepQuality) -> UIColor {
        switch quality {
        case .poor:      return UIColor(hex: "#FF6B6B")
        case .fair:      return UIColor(hex: "#FFB347")
        case .good:      return UIColor(hex: "#4CAF50")
        case .excellent: return UIColor(hex: "#7BC8F6")
        }
    }

    private func tipText(for quality: SleepQuality) -> String {
        switch quality {
        case .poor:      return "Try to get at least 7 h of sleep. Poor sleep worsens PCOS symptoms."
        case .fair:      return "You're close! An extra 30–60 min of sleep can improve hormone balance."
        case .good:      return "Great sleep! Steady 7–8 h helps regulate cortisol and insulin."
        case .excellent: return "Excellent sleep supports hormone balance and energy levels. Keep it up!"
        }
    }
}
