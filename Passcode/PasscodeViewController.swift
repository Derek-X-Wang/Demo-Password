//
//  PasscodeViewController.swift
//  Passcode
//
//  Created by Xinzhe Wang on 1/24/18.
//  Copyright © 2018 IntBridge. All rights reserved.
//

import UIKit
import AWSUserPoolsSignIn

class PasscodeViewController: UIViewController {

    @IBOutlet weak var passcodeTextField: KaedeTextField!
    
    var destination: String?
    var mfaCodeCompletionSource: AWSTaskCompletionSource<NSString>?
    
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
        // check if the user is not providing an empty authentication code
        guard let authenticationCodeValue = passcodeTextField.text, !authenticationCodeValue.isEmpty else {
            let alert = UIAlertController(title: "Authentication Code Missing",
                                          message: "Please enter the autentication code you received by E-mail / SMS.",
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            self.present(alert, animated: true, completion:nil)
            return
        }
        self.mfaCodeCompletionSource?.set(result: authenticationCodeValue as NSString)
    }
    
}

extension PasscodeViewController : AWSCognitoIdentityMultiFactorAuthentication {
    
    func didCompleteMultifactorAuthenticationStepWithError(_ error: Error?) {
        if let localError = error as? NSError {
            DispatchQueue.main.async(execute: {
                let alert = UIAlertController(title: localError.userInfo["__type"] as? String,
                                              message:localError.userInfo["message"] as? String,
                                              preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                self.present(alert, animated: true, completion:nil)
            })
        }
    }
    
    func getCode(_ authenticationInput: AWSCognitoIdentityMultifactorAuthenticationInput, mfaCodeCompletionSource: AWSTaskCompletionSource<NSString>) {
        self.mfaCodeCompletionSource = mfaCodeCompletionSource
        self.destination = authenticationInput.destination
    }
    
}
