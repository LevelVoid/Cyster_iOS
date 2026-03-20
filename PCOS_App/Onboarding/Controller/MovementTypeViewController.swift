//
//  MovementTypeViewController.swift
//  PCOS_App
//
//  Created by SDC-USER on 17/01/26.
//

import UIKit

class MovementTypeViewController: UIViewController {

    @IBOutlet weak var sedentaryView: UIView!
    @IBOutlet weak var lightMovementsView: UIView!
    @IBOutlet weak var regularMovementsView: UIView!
    @IBOutlet weak var veryActiveView: UIView!
    
    @IBOutlet weak var nextButton: UIButton!
    private var selectedView: UIView?
    private var selectedMovementType: String?
    
    // Store original background colors
    private var originalBackgroundColors: [Int: UIColor] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        nextButton.tintColor = UIColor(hex:"FE7A96")
        sedentaryView.layer.cornerRadius = 20
        lightMovementsView.layer.cornerRadius = 20
        regularMovementsView.layer.cornerRadius = 20
        veryActiveView.layer.cornerRadius = 20
        
        // Start at 35% opacity — button stays enabled so iOS never overrides with grey
        nextButton.alpha = 0.5
        
        // Add tap gestures to each view (this assigns tags)
        addTapGesture(to: sedentaryView, movementType: "Sedentary Type")
        addTapGesture(to: lightMovementsView, movementType: "Light Movements")
        addTapGesture(to: regularMovementsView, movementType: "Regular Movements")
        addTapGesture(to: veryActiveView, movementType: "Very active on most days")
        
        // Store original background colors AFTER tags are assigned
        let allViews = [sedentaryView, lightMovementsView, regularMovementsView, veryActiveView]
        for view in allViews {
            if let view = view {
                originalBackgroundColors[view.tag] = view.backgroundColor
            }
        }
    }
    
    private func addTapGesture(to view: UIView, movementType: String) {
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(viewTapped(_:)))
            view.isUserInteractionEnabled = true
            view.tag = getTag(for: movementType)
            view.addGestureRecognizer(tapGesture)
        }
    private func getTag(for movementType: String) -> Int {
    switch movementType {
    case "Sedentary Type": return 1
    case "Light Movements": return 2
    case "Regular Movements": return 3
    case "Very active on most days": return 4
    default: return 0
    }
        }
    
    private func getMovementType(from tag: Int) -> String {
            switch tag {
            case 1: return "Sedentary Type"
            case 2: return "Light Movements"
            case 3: return "Regular Movements"
            case 4: return "Very active on most days"
            default: return ""
            }
        }
    @objc private func viewTapped(_ gesture: UITapGestureRecognizer) {
            guard let tappedView = gesture.view else { return }
            
            // Deselect previous view - restore original background color
            if let previousView = selectedView {
                previousView.layer.borderWidth = 0
                previousView.backgroundColor = originalBackgroundColors[previousView.tag] ?? UIColor(red: 0.95, green: 0.85, blue: 0.90, alpha: 1.0)
            }
            
            // Select new view
            selectedView = tappedView
            selectedMovementType = getMovementType(from: tappedView.tag)
            
            // Highlight selected view
            tappedView.layer.borderWidth = 3
        tappedView.layer.borderColor = UIColor(hex:"#fe7a96").cgColor
        tappedView.backgroundColor = UIColor(hex:"#fe7a96").withAlphaComponent(0.1)
            
            // Restore full opacity now that a selection is made
            nextButton.alpha = 1.0
        }

    @IBAction func nextButtonTapped(_ sender: UIButton) { }

    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        guard let movementType = selectedMovementType else { return false }
        // Save BEFORE the segue fires — IBAction timing is unreliable with button-wired segues
        UserDefaults.standard.set(movementType, forKey: "userWorkoutType")
        print("Saved movement type: \(movementType)")
        return true
    }
    
}
