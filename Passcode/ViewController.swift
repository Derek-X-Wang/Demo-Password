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

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !AWSSignInManager.sharedInstance().isLoggedIn {
            let signInVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SignInViewController")
            self.present(signInVC, animated: true, completion: nil)
        }
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

