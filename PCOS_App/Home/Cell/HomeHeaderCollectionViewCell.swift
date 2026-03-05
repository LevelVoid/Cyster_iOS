//
//  HomeHeaderCollectionViewCell.swift
//  PCOS_App
//
//  Created by SDC-USER on 08/01/26.
//

import UIKit

protocol HomeHeaderCollectionViewCellDelegate: AnyObject {
    func homeHeaderCellDidTapLogPeriod(_ cell: HomeHeaderCollectionViewCell)
}

class HomeHeaderCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var headerImageView: UIImageView!
    @IBOutlet weak var gradientOverlayView: UIView!
    
    @IBOutlet weak var quoteLabel: UILabel!
    
    @IBOutlet weak var cycleDayLabel: UILabel!
    @IBOutlet weak var logPeriodButton: UIButton!
    
    weak var delegate: HomeHeaderCollectionViewCellDelegate?
    
    private let gradientLayer = CAGradientLayer()

    // Programmatic labels for phase name and quote
    private let phaseLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20, weight: .semibold)
        label.textColor = .black
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let phaseQuoteLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .regular)
        label.textColor = .darkGray
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private var phaseLabelsAdded = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setup()
        setupMultiStopGradient()
        addPhaseLabels()
    }
    
    private func setup() {
        headerImageView.image = UIImage(named: "home_image_trial_2")
        headerImageView.contentMode = .scaleToFill
        headerImageView.clipsToBounds = true
        
        logPeriodButton.layer.cornerRadius = 30
        logPeriodButton.tintColor = UIColor(hex: "#FE7A96")
        logPeriodButton.addTarget(self, action: #selector(logPeriodButtonTapped), for: .touchUpInside)
    }
    
    @objc private func logPeriodButtonTapped() {
        delegate?.homeHeaderCellDidTapLogPeriod(self)
    }
    
    private func setupMultiStopGradient() {
        gradientOverlayView.backgroundColor = .clear
        gradientLayer.colors = [
            UIColor.black.cgColor,
            UIColor.black.cgColor,
            UIColor.clear.cgColor
        ]
        gradientLayer.locations = [0.0, 0.9, 0.95]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
        headerImageView.layer.mask = gradientLayer
        self.contentView.backgroundColor = UIColor(hex: "#FCEEED")
    }

    private func addPhaseLabels() {
        guard !phaseLabelsAdded else { return }
        phaseLabelsAdded = true

        contentView.addSubview(phaseLabel)
        contentView.addSubview(phaseQuoteLabel)

        NSLayoutConstraint.activate([
            phaseLabel.topAnchor.constraint(equalTo: cycleDayLabel.bottomAnchor, constant: 4),
            phaseLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),

            phaseQuoteLabel.topAnchor.constraint(equalTo: phaseLabel.bottomAnchor, constant: 8),
            phaseQuoteLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 32),
            phaseQuoteLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -32)
        ])
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = headerImageView.bounds
    }

    // MARK: - Public Configuration

    func configure(cycleDay: Int, phase: Phase) {
        cycleDayLabel.text = "Cycle Day \(cycleDay)"
        phaseLabel.text = phase.displayName
        phaseQuoteLabel.text = phase.quote

        // Hide ALL XIB labels inside gradientOverlayView except cycleDayLabel
        // This covers the "Menstrual Phase" label (no outlet) and quoteLabel
        if let overlay = gradientOverlayView {
            for subview in overlay.subviews {
                if let label = subview as? UILabel, label !== cycleDayLabel {
                    label.isHidden = true
                }
            }
        }
    }
}

