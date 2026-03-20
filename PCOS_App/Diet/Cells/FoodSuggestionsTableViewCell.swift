//
//  FoodSuggestionsTableViewCell.swift
//  PCOS_App
//
//  Created by SDC-USER on 20/03/26.
//

import UIKit

class FoodSuggestionsTableViewCell: UITableViewCell {

    @IBOutlet weak var mainContent: UIView!
    static let identifier = "FoodSuggestionsTableViewCell"
    static func nib() -> UINib {
        return UINib(nibName: "FoodSuggestionsTableViewCell", bundle: nil)
    }
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
