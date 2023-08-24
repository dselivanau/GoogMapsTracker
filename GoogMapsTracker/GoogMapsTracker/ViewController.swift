//
//  ViewController.swift
//  GoogMapsTracker
//
//  Created by innowise on 8/24/23.
//

import UIKit
import FirebaseAuth

class ViewController: UIViewController {
    @IBOutlet weak var enterEmail: UITextField!
    @IBOutlet weak var enterPassword: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        let signedInUser = UserDefaults.standard.string(forKey: "id")
        if signedInUser != nil {
            print("User signed in")
            self.navigationController?.pushViewController(MapsViewContoller(), animated: true)
//            self.present(MapsViewContoller(), animated: true)
        } else {
            print("User not signed in")
        }
    }
    
    func signUpUser() {
        // 1
        guard let email = enterEmail.text, let password = enterPassword.text, !email.isEmpty, !password.isEmpty else { return }
        
        // 2
        Auth.auth().createUser(withEmail: email, password: password) { _, error in
            // 3
            if error == nil {
                Auth.auth().signIn(withEmail: email, password: password)
            } else {
                print("Error in createUser: \(error?.localizedDescription ?? "")")
            }
        }
    }
    
    @IBAction func signUpButton(_ sender: Any) {
        signUpUser()
    }
    
    @IBAction func signInButton(_ sender: Any) {
        guard
            let email = enterEmail.text,
            let password = enterPassword.text,
            !email.isEmpty,
            !password.isEmpty
        else { return }
        
        Auth.auth().signIn(withEmail: email, password: password) { user, error in
            if let error = error, user == nil {
                let alert = UIAlertController(
                    title: "Sign In Failed",
                    message: error.localizedDescription,
                    preferredStyle: .alert)
                
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(alert, animated: true, completion: nil)
            }
            
            if user != nil {
                print(user?.user.uid)
                UserDefaults.standard.set(user!.user.uid, forKey: "id")
                print("Without error")
            }
            
            
        }
    }
    @IBAction func logoutBUtton(_ sender: Any) {
        UserDefaults.standard.removeObject(forKey: "id")
        print("removed id")
    }
}

