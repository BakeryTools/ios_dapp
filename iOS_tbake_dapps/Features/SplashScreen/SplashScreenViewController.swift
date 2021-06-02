//
//  SplashScreenViewController.swift
//  iOS_tbake_dapps
//
//  Created by Danial on 23/05/2021.
//  Copyright © 2020 Danial. All rights reserved.
//

import UIKit

class SplashScreenViewController: UIViewController {

    @IBOutlet weak var backgroundImgView: UIImageView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var splashScreenLogo: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        activityIndicator.isHidden = false //userHasLoggedIn() ? false : true
        activityIndicator.color = UIColor.hexStringToUIColor(hex: "#A05314", 1.0)
        activityIndicator.startAnimating()
        
        // will not call any API when device is jailbroken
       
        if isJailbroken() {
            // requires root view controller to prompt this alert
            let alert = UIAlertController(title: "Jailbroken Device Detected", message: "Unable to proceed with Recommend.my App as the system does not support rooted phone.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
                // quit app
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    exit(0)
                }
            }))

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                let sceneDelegate = self.view.window?.windowScene?.delegate as? SceneDelegate
                sceneDelegate?.getTopMostViewController()?.present(alert, animated: true)
            }
            
            return
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            let sceneDelegate = self.view.window?.windowScene?.delegate as? SceneDelegate
            sceneDelegate?.initRootController()
            self.activityIndicator.stopAnimating()
        }
    }
    
    deinit {
        #if DEBUG
        print("🌍🌍🌍 Deinit SplashScreenViewController 🌍🌍🌍")
        #endif
    }
}
