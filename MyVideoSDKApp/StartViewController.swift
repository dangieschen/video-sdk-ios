//
//  StartViewController.swift
//  MyVideoSDKApp
//

import UIKit
import ZoomVideoSDK

class StartViewController: UIViewController {
    
    var enterSessionButton: UIButton!

    override func loadView() {
        super.loadView()
        
        enterSessionButton = UIButton(type: .system)
        enterSessionButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(enterSessionButton)
        
        NSLayoutConstraint.activate([
            enterSessionButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            enterSessionButton.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .gray
        
        enterSessionButton.backgroundColor = .white
        enterSessionButton.layer.cornerRadius = 8
        enterSessionButton.setTitle("Enter Session", for: .normal)
        enterSessionButton.addTarget(self, action: #selector(enterButtonTapped(_:)), for: .touchUpInside)

        // **Do not call setupSDK() here.** Initialization should be done once (e.g., AppDelegate)
        // remove the call to setupSDK()
    }
    
    @IBAction func enterButtonTapped(_ sender: UIButton) {
        enterSessionButton.isEnabled = false
        let sessionViewController = SessionViewController()
        sessionViewController.modalPresentationStyle = .fullScreen
        present(sessionViewController, animated: false) {
            self.enterSessionButton.isEnabled = true
        }
    }
}
