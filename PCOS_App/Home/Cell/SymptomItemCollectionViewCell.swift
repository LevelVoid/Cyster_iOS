import UIKit

class SymptomItemCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var cell: UIView!
    @IBOutlet weak var IconImage: UIImageView!
    @IBOutlet weak var symptomLabel: UILabel!

    static let identifier = "SymptomItemCollectionViewCell"

    override func awakeFromNib() {
        super.awakeFromNib()

        if IconImage != nil && symptomLabel != nil {
            setupUI()
        }
    }

    private func setupUI(){
        contentView.backgroundColor = .clear
        contentView.layer.cornerRadius = 20
        contentView.clipsToBounds = true

        IconImage?.layer.cornerRadius = 16 
        IconImage?.clipsToBounds = true
        IconImage?.contentMode = .scaleAspectFit
        IconImage?.backgroundColor = .clear 

        IconImage.clipsToBounds = true
    }

    func configure(with symptom: SymptomItem, isSelected: Bool) {
        guard let iconImage = IconImage, let label = symptomLabel else {
            print("Error in configure: IBOutlets are nil")
            return
        }
        label.text = symptom.name
        label.textColor = .black
        iconImage.image = UIImage(named: symptom.icon)
        updateSelectionState(isSelected)

    }

    func configureWithCategory(with symptom: SymptomItem) {
        guard let iconImage = IconImage, let label = symptomLabel else { return }

        label.text = symptom.category

        label.textColor = .black
        iconImage.image = UIImage(named: symptom.icon)

        contentView.backgroundColor = .clear
        iconImage.layer.borderWidth = 0
    }

    private func updateSelectionState(_ isSelected: Bool) {
        if isSelected {
            contentView.backgroundColor = UIColor.systemGray3
            IconImage.layer.borderWidth = 4
            IconImage.layer.borderColor = UIColor(hex: "fe7a96").cgColor
        } else {
            contentView.backgroundColor = .clear
            IconImage.layer.borderWidth = 0
            IconImage.layer.borderColor = UIColor.clear.cgColor
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        contentView.backgroundColor = .clear
        symptomLabel.textColor = .gray
        IconImage.tintColor = .gray
    }

}
