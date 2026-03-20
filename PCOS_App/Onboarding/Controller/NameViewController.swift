//
//  NameViewController.swift
//  PCOS_App
//
//  Created by SDC-USER on 17/01/26.
//

import UIKit

class NameViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var nextButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        nameField.layer.cornerRadius = 10
        nameField.delegate = self
        nextButton.tintColor = UIColor(hex: "FE7A96")

        nextButton.alpha = 0.5

        // Listen for text changes
        nameField.addTarget(self, action: #selector(nameFieldChanged), for: .editingChanged)

        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    @objc private func nameFieldChanged() {
        let hasText = !(nameField.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
        nextButton.alpha = hasText ? 1.0 : 0.5
    }

    // Fallback: always dismiss keyboard when touching the view
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
        super.touchesBegan(touches, with: event)
    }

    // Dismiss keyboard when user taps Return key
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    @IBAction func NextButtonTapped(_ sender: UIButton) {
        let name = nameField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !name.isEmpty else { return }
        UserDefaults.standard.set(name, forKey: "userName")
        performSegue(withIdentifier: "showDOB", sender: nil)
    }
}
