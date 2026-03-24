//
//  Phase01ViewController.swift
//  PCOS_App
//
//  Created by Dnyaneshwari Gogawale on 19/02/26.
//

import UIKit

class Phase01ViewController: UIViewController {
    @IBOutlet weak var CycleImage: UIImageView!
    @IBOutlet weak var card1View:UIView!
    @IBOutlet weak var CycleInformation: UILabel!
    @IBOutlet weak var heading: UILabel!
    var phaseSignal: PhaseSignal!

        // MARK: - Lifecycle
        override func viewDidLoad() {
            super.viewDidLoad()
            setupUI()
        }

        // MARK: - UI Setup
        private func setupUI() {

            // Heading
            heading.text = phaseSignal.understanding.heading

            // Hide the old single label
            CycleInformation.isHidden = true
            
            // Hide the old single card background
            card1View.backgroundColor = .clear
            
            // Put multiple lines in separate stylized cards
            let stackView = UIStackView()
            stackView.axis = .vertical
            stackView.spacing = 16
            stackView.translatesAutoresizingMaskIntoConstraints = false
            
            for description in phaseSignal.understanding.descriptions {
                
                let card = UIView()
                card.backgroundColor = .white
                card.layer.cornerRadius = 16
                card.translatesAutoresizingMaskIntoConstraints = false
                
                let label = UILabel()
                label.text = description
                label.font = CycleInformation.font
                label.textColor = CycleInformation.textColor
                label.numberOfLines = 0
                label.textAlignment = .natural
                label.translatesAutoresizingMaskIntoConstraints = false
                
                card.addSubview(label)
                
                NSLayoutConstraint.activate([
                    label.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
                    label.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
                    label.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
                    label.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16)
                ])
                
                stackView.addArrangedSubview(card)
            }
            
            card1View.addSubview(stackView)
            
            NSLayoutConstraint.activate([
                stackView.topAnchor.constraint(equalTo: card1View.topAnchor, constant: 0),
                stackView.leadingAnchor.constraint(equalTo: card1View.leadingAnchor, constant: 0),
                stackView.trailingAnchor.constraint(equalTo: card1View.trailingAnchor, constant: 0),
                stackView.bottomAnchor.constraint(lessThanOrEqualTo: card1View.bottomAnchor, constant: 0)
            ])

            // Illustration
            // CycleImage.image = UIImage(named: phaseSignal.illustration)
            // CycleImage.contentMode = .scaleAspectFit
            CycleImage.isHidden = true
        }

    

}
