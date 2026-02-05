//
//  SignalsCollectionViewCell.swift
//  PCOS_App
//
//  Created by SDC-USER on 05/02/26.
//

import UIKit

class SignalsCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var SignalsCardView: UIView!
    
    @IBOutlet weak var SignalsLabel: UILabel!
    @IBOutlet weak var SignalsImage: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        SignalsCardView.layer.cornerRadius = 10
    }
    
    func configure(with signalInfo: SignalInfo) {
        SignalsLabel.text = signalInfo.title
        
        // Try to load the image, use default if not found
        if let image = UIImage(named: signalInfo.imageName) {
            SignalsImage.image = image
        } else {
            // Use a default system image or placeholder
            SignalsImage.image = UIImage(systemName: "heart.text.square.fill")
            SignalsImage.tintColor = .systemPink
        }
    }
    
    func configureDefault() {
        SignalsLabel.text = "Track your PCOS signals"
        SignalsImage.image = UIImage(systemName: "chart.line.uptrend.xyaxis")
        SignalsImage.tintColor = .systemBlue
    }

}
