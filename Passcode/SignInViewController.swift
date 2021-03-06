//
//  SignInViewController.swift
//  Passcode
//
//  Created by Xinzhe Wang on 1/24/18.
//  Copyright © 2018 IntBridge. All rights reserved.
//

import UIKit
import AWSUserPoolsSignIn
import AWSDynamoDB
import AWSFacebookSignIn

class SignInViewController: UIViewController {

    @IBOutlet weak var phoneNumberTextField: KaedeTextField!
    @IBOutlet weak var facebookButton: UIButton!
    
    var passwordAuthenticationCompletion: AWSTaskCompletionSource<AnyObject>?
    var didCompleteSignIn: ((_ success: Bool) -> Void)? = nil
    var password: String?
    var sentTo: String?
    var pool: AWSCognitoIdentityUserPool?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.pool = AWSCognitoIdentityUserPool.default()
        //self.pool?.delegate = self
        
        AWSFacebookSignInProvider.sharedInstance().setPermissions(["public_profile"])
        // Facebook UI Setup
        let facebookComponent = AWSFacebookSignInButton(frame: CGRect(x: 0, y: 0, width: facebookButton.frame.size.width, height: facebookButton.frame.size.height))
        facebookComponent.buttonStyle = .large // use the large button style
        facebookComponent.delegate = self // set delegate to respond to user actions
        facebookButton.addSubview(facebookComponent)
        didCompleteSignIn = { success in
            print("FB login success")
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("login is \(AWSSignInManager.sharedInstance().isLoggedIn)")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let signUpConfirmationViewController = segue.destination as? ConfirmViewController {
            signUpConfirmationViewController.sentTo = self.sentTo
            signUpConfirmationViewController.password = self.password
            signUpConfirmationViewController.phone = phoneNumberTextField.text
            let username = "MobZ\(phoneNumberTextField.text!)"
            signUpConfirmationViewController.user = self.pool!.getUser(username)
        }
    }
    

    @IBAction func onSignUp(_ sender: Any) {
        guard let phone = self.phoneNumberTextField.text, !phone.isEmpty else {
            DispatchQueue.main.async(execute: {
                let alert = UIAlertController(title: "Missing Phone Number",
                                              message:"Please enter a valid number.",
                                              preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                self.present(alert, animated: true, completion:nil)
            })
            return
        }
        var attributes = [AWSCognitoIdentityUserAttributeType]()
        
        let phoneAttr = AWSCognitoIdentityUserAttributeType()
        phoneAttr?.name = "phone_number"
        phoneAttr?.value = phone
        attributes.append(phoneAttr!)
        
        password = UUID().uuidString
        let username = "MobZ\(phone)"
        self.pool?.signUp(username, password: password!, userAttributes: attributes, validationData: nil).continueWith { (task) -> Any? in
            DispatchQueue.main.async(execute: {
                if let error = task.error as? NSError {
                    let alert = UIAlertController(title: error.userInfo["__type"] as? String,
                                                  message:error.userInfo["message"] as? String,
                                                  preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                    print(error.localizedDescription)
                    self.present(alert, animated: true, completion:nil)
                    return
                }
                
                if let result = task.result as AWSCognitoIdentityUserPoolSignUpResponse! {
                    // handle the case where user has to confirm his identity via email / SMS
                    if (result.user.confirmedStatus != AWSCognitoIdentityUserStatus.confirmed) {
                        self.sentTo = result.codeDeliveryDetails?.destination
                        self.performSegue(withIdentifier: "SignUpConfirmSegue", sender:sender)
                    } else {
                        let alert = UIAlertController(title: "Registration Complete",
                                                      message: "Registration was successful.",
                                                      preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: {(action) in
                            _ = self.navigationController?.popToRootViewController(animated: true)
                        }))
                        self.present(alert, animated: true, completion: nil)
                    }
                }
                
            })
            return nil
        }
    }
    
    @IBAction func onSignIn(_ sender: Any) {
        let dynamoDBObjectMapper = AWSDynamoDBObjectMapper.default()
        dynamoDBObjectMapper.load(User.self, hashKey: phoneNumberTextField.text!, rangeKey: nil).continueWith { (task) -> Any? in
            if let error = task.error as NSError? {
                print("The request failed. Error: \(error)")
            } else {
                print("\(task.result)")
            }
            return nil
        }
    }
    
    func signIn(_ signInProvider: AWSSignInProvider) {
        AWSSignInManager.sharedInstance().login(signInProviderKey: signInProvider.identityProviderName, completionHandler: {(result: Any?, error: Error?) in
            print("result = \(result), error = \(error)")
            // If no error reported by SignInProvider, discard the sign-in view controller.
            if error == nil {
                return
            }
        })
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
    
    func showErrorDialog(_ loginProviderName: String, withError error: NSError) {
        print("\(loginProviderName) failed to sign in w/ error: \(error)")
        let alertController = UIAlertController(title: NSLocalizedString("Sign-in Provider Sign-In Error", comment: "Sign-in error for sign-in failure."), message: NSLocalizedString("\(loginProviderName) failed to sign in w/ error: \(error)", comment: "Sign-in message structure for sign-in failure."), preferredStyle: .alert)
        let doneAction = UIAlertAction(title: NSLocalizedString("Ok", comment: "Label to cancel sign-in failure."), style: .cancel, handler: nil)
        alertController.addAction(doneAction)
        present(alertController, animated: true, completion: nil)
    }

}

// fb login
extension SignInViewController: AWSSignInDelegate {
    // delegate handler for facebook / google sign in.
    func onLogin(signInProvider: AWSSignInProvider, result: Any?, error: Error?) {
        // dismiss view controller if no error
        if error == nil {
            print("Signed in with: \(signInProvider)")
            self.presentingViewController?.dismiss(animated: true, completion: nil)
            if let didCompleteSignIn = self.didCompleteSignIn {
                didCompleteSignIn(true)
            }
            return
        }
        self.showErrorDialog(signInProvider.identityProviderName, withError: error as! NSError)
    }

}

extension SignInViewController: AWSCognitoUserPoolsSignInHandler {
    func handleUserPoolSignInFlowStart() {
        guard let phone = self.phoneNumberTextField.text, !phone.isEmpty else {
                DispatchQueue.main.async(execute: {
                    let alert = UIAlertController(title: "Missing Phone Number",
                                                  message:"Please enter a valid number.",
                                                  preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                    self.present(alert, animated: true, completion:nil)
                })
                return
        }
        // set the task completion result as an object of AWSCognitoIdentityPasswordAuthenticationDetails with username and password that the app user provides
        self.passwordAuthenticationCompletion?.set(result: AWSCognitoIdentityPasswordAuthenticationDetails(username: phone, password: password!))
    }
}

// Extension to adopt the `AWSCognitoIdentityInteractiveAuthenticationDelegate` protocol
extension SignInViewController: AWSCognitoIdentityInteractiveAuthenticationDelegate {
    
    // this function handles the UI setup for initial login screen, in our case, since we are already on the login screen, we just return the View Controller instance
    func startPasswordAuthentication() -> AWSCognitoIdentityPasswordAuthentication {
        return self
    }
    
    // prepare and setup the ViewController that manages the Multi-Factor Authentication
    func startMultiFactorAuthentication() -> AWSCognitoIdentityMultiFactorAuthentication {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: "PasscodeViewController")
        DispatchQueue.main.async(execute: {
            self.present(viewController, animated: true, completion: nil)
        })
        return viewController as! AWSCognitoIdentityMultiFactorAuthentication
    }
}

// Extension to adopt the `AWSCognitoIdentityPasswordAuthentication` protocol
extension SignInViewController: AWSCognitoIdentityPasswordAuthentication {
    
    func getDetails(_ authenticationInput: AWSCognitoIdentityPasswordAuthenticationInput, passwordAuthenticationCompletionSource: AWSTaskCompletionSource<AWSCognitoIdentityPasswordAuthenticationDetails>) {
        self.passwordAuthenticationCompletion = passwordAuthenticationCompletionSource as? AWSTaskCompletionSource<AnyObject>
    }
    
    func didCompleteStepWithError(_ error: Error?) {
        if let error = error as? NSError {
            DispatchQueue.main.async(execute: {
                
                let alert = UIAlertController(title: error.userInfo["__type"] as? String,
                                              message:error.userInfo["message"] as? String,
                                              preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                self.present(alert, animated: true, completion:nil)
            })
        }
    }
}
