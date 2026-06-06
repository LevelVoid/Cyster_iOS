import UIKit

class FoodListTeableViewCell: UITableViewCell {

    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var foodNamleLabel: UILabel!

     override func awakeFromNib() {
         super.awakeFromNib()
         setupUI()
     }

     override func setSelected(_ selected: Bool, animated: Bool) {
         super.setSelected(selected, animated: animated)

         UIView.animate(withDuration: 0.1) {
             self.containerView.backgroundColor = selected ? UIColor.systemGray6 : .white
         }
     }

     override func prepareForReuse() {
         super.prepareForReuse()
         foodNamleLabel.text = nil
         containerView.backgroundColor = .white
     }

     private func setupUI() {
         selectionStyle = .none
         backgroundColor = .clear
         contentView.backgroundColor = .clear

         containerView.backgroundColor = .white
         containerView.layer.cornerRadius = 12
         containerView.layer.borderWidth = 1
         containerView.layer.borderColor = UIColor.systemGray5.cgColor

         containerView.layer.shadowColor = UIColor.black.cgColor
         containerView.layer.shadowOffset = CGSize(width: 0, height: 1)
         containerView.layer.shadowOpacity = 0.05
         containerView.layer.shadowRadius = 2
         containerView.layer.masksToBounds = false

         foodNamleLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
         foodNamleLabel.textColor = .label

         accessoryType = .disclosureIndicator
     }

     func configure(with foodItem: FoodItem) {
         foodNamleLabel.text = foodItem.name
     }
 }
