//
//  SignUpViewController.swift
//  iOS_tbake_dapps
//
//  Created by Danial on 24/05/2021.
//

import UIKit

protocol SignUpDelegate: AnyObject {
    func doRegister(postAction: Bool?)
}

class SignUpViewController: UIViewController {

    weak var delegate: SignUpDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }


    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
