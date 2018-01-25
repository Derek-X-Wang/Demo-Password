//
//  ConfirmViewController.swift
//  Passcode
//
//  Created by Xinzhe Wang on 1/24/18.
//  Copyright © 2018 IntBridge. All rights reserved.
//

import UIKit
import AWSUserPoolsSignIn
import AWSDynamoDB

class ConfirmViewController: UIViewController {
    
    @IBOutlet weak var confirmCodeTextField: KaedeTextField!
    var sentTo: String?
    var phone: String?
    var password: String?
    var user: AWSCognitoIdentityUser?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    // This is used to dismiss the keyboard, user just has to tap outside the
    // user name and password views and it will dismiss
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            if touch.phase == UITouchPhase.began {
                view.endEditing(true)
            }
        }
        
        super.touchesBegan(touches , with:event)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    @IBAction func onConfirm(_ sender: Any) {
        guard let confirmationCodeValue = self.confirmCodeTextField.text, !confirmationCodeValue.isEmpty else {
            let alert = UIAlertController(title: "Confirmation code missing.",
                                          message: "Please enter a valid confirmation code.",
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            self.present(alert, animated: true, completion:nil)
            return
        }
        self.user?.confirmSignUp(confirmationCodeValue, forceAliasCreation: true).continueWith(block: {[weak self] (task: AWSTask) -> AnyObject? in
            guard let strongSelf = self else { return nil }
            if let error = task.error as? NSError {
                DispatchQueue.main.async {
                    let alert = UIAlertController(title: "Error",
                                                  message:error.userInfo["message"] as? String,
                                                  preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                    strongSelf.present(alert, animated: true, completion:nil)
                }
            } else {
                strongSelf.saveDynamoDB {
                    DispatchQueue.main.async {
                        let alert = UIAlertController(title: "Registration Complete",
                                                      message: "Registration was successful.",
                                                      preferredStyle: .alert)
                        
                        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: {(action) in
                            strongSelf.dismiss(animated: true, completion: nil)
                        }))
                        strongSelf.present(alert, animated: true, completion: nil)
                    }
                }
                
            }
            return nil
        })
    }
    
    func saveDynamoDB(_ done: @escaping () -> Void) {
        let newUser = User()
        newUser?._phone = phone
        newUser?._password = password
        let dynamoDBObjectMapper = AWSDynamoDBObjectMapper.default()
        dynamoDBObjectMapper.save(newUser!) { (error) in
            if let error = error as NSError? {
                print("The request failed. Error: \(error)")
            } else {
                done()
            }
        }
    }

}
