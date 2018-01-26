//
//  ViewController.swift
//  Passcode
//
//  Created by Xinzhe Wang on 1/24/18.
//  Copyright © 2018 IntBridge. All rights reserved.
//

import UIKit
import AWSAuthCore
import AWSAuthUI
import AWSDynamoDB

class ViewController: UIViewController {
    
    var contactManager: AWSContactManager?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        if AWSSignInManager.sharedInstance().isLoggedIn {
//            let newContact = PCContact()
//            newContact?._userId = AWSIdentityManager.default().identityId!
//            newContact?._contactId = UUID().uuidString
//            newContact?._company = "here"
//            newContact?._firstName = "Derek2"
//            let dynamoDBObjectMapper = AWSDynamoDBObjectMapper.default()
//            dynamoDBObjectMapper.save(newContact!).continueWith(block: { (task) -> Any? in
//                if let error = task.error as? NSError {
//                    let alert = UIAlertController(title: error.userInfo["__type"] as? String,
//                                                  message:error.userInfo["message"] as? String,
//                                                  preferredStyle: .alert)
//                    alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
//                    print(error.localizedDescription)
//                    self.present(alert, animated: true, completion:nil)
//                    return nil
//                }
//                print("dynamoDBObjectMapper saved")
//                return nil
//            })

//            if let id = AWSIdentityManager.default().identityId {
//                print("identityId is \(id)")
//                let newUser = User()
//                newUser?._phone = "testing"
//                newUser?._password = "password"
//                let dynamoDBObjectMapper = AWSDynamoDBObjectMapper.default()
//                dynamoDBObjectMapper.save(newUser!) { (error) in
//                    if let error = error as NSError? {
//                        print("The request failed. Error: \(error)")
//                    }
//                    print("dynamoDBObjectMapper saved")
//                }
//            } else {
//                print("identityId is null")
//                AWSIdentityManager.default().credentialsProvider.getIdentityId().continueOnSuccessWith(block: { (task) -> Any? in
//                    let cognitoId = task.result! as String
//                    print("get identityId as \(cognitoId)")
//                    let newUser = User()
//                    newUser?._phone = "testing"
//                    newUser?._password = "password"
//                    let dynamoDBObjectMapper = AWSDynamoDBObjectMapper.default()
//                    dynamoDBObjectMapper.save(newUser!) { (error) in
//                        if let error = error as NSError? {
//                            print("The request failed. Error: \(error)")
//                        }
//                        print("dynamoDBObjectMapper saved")
//                    }
//                    return nil
//                })
//            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !AWSSignInManager.sharedInstance().isLoggedIn {
            let signInVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SignInViewController")
            self.present(signInVC, animated: true, completion: nil)
        } else {
            if let id = AWSIdentityManager.default().identityId {
                setupContactManager(id)
            } else {
                print("identityId is null")
                AWSIdentityManager.default().credentialsProvider.getIdentityId().continueOnSuccessWith(block: { (task) -> Any? in
                    let cognitoId = task.result! as String
                    print("get identityId as \(cognitoId)")
                    self.setupContactManager(cognitoId)
                    return nil
                })
            }
        }
        
    }
    
    func setupContactManager(_ id: String) {
        contactManager = AWSContactManager(id)
        self.contactManager?.fetchContacts()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func onLogout(_ sender: Any) {
        if AWSSignInManager.sharedInstance().isLoggedIn {
            print("prepare to logout")
            AWSSignInManager.sharedInstance().logout(completionHandler: {(result: Any?, error: Error?) in
                let signInVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SignInViewController")
                self.present(signInVC, animated: true, completion: nil)
            })
        }
    }
    
}

