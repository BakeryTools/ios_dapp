//
//  SignInViewController.swift
//  iOS_tbake_dapps
//
//  Created by Danial on 24/05/2021.
//

import UIKit

protocol SignInDelegate: AnyObject {
    func doLogin(postAction: Bool?)
}

class SignInViewController: UIViewController {

    @IBOutlet weak var emailLbl: UILabel!
    @IBOutlet weak var notRegisterYetLbl: UILabel!
    @IBOutlet weak var errorLbl: UILabel!
    
    @IBOutlet weak var emailTextField: UITextField!
    
    @IBOutlet weak var forgotPasswordBtn: UIButton!
    @IBOutlet weak var submitBtn: UIButton!
    
    weak var delegate: SignInDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    //MARK:- Setup View
    func setupLbl() {
        self.emailLbl.text = "Email"
        self.notRegisterYetLbl.text = "Not a user yet? Sign Up"
        self.notRegisterYetLbl.ChangeCertainTextColor(fullText: self.notRegisterYetLbl.text ?? "", changeText: "Sign Up", color: UIColor.hexStringToUIColor(hex: "#FE6220", 1.0))
        self.notRegisterYetLbl.isUserInteractionEnabled = true
        self.notRegisterYetLbl.lineBreakMode = .byWordWrapping
        let tapGesture = UITapGestureRecognizer.init(target: self, action: #selector(tappedOnLabel(_:)))
        tapGesture.numberOfTouchesRequired = 1
        self.notRegisterYetLbl.addGestureRecognizer(tapGesture)
        
        self.errorLbl.isHidden = true
    }
    
    func setupTextField() {
        self.emailTextField.placeholder = "bakerytools@business.com"
    }
    
    //MARK:- Action Function
    @objc func tappedOnLabel(_ gesture: UITapGestureRecognizer) {
        guard let text = self.notRegisterYetLbl.text else { return }
        let signupRange = (text as NSString).range(of: "Sign Up")
        if gesture.didTapAttributedTextInLabel(label: self.notRegisterYetLbl, inRange: signupRange) {
            let SignUpPage = SignUpViewController(nibName: "SignUpViewController", bundle: nil)
            SignUpPage.delegate = self
            let nib = UINavigationController(rootViewController: SignUpPage)
            nib.modalPresentationStyle = .fullScreen
            nib.modalTransitionStyle = .crossDissolve
            self.present(nib, animated: false, completion: nil)
        }
    }
}

//MARK:- Register Delegate
extension SignInViewController: SignUpDelegate {
    func doRegister(postAction: Bool?) {
        switch postAction {
        case true:
            self.delegate?.doLogin(postAction: true)
        default:
            self.delegate?.doLogin(postAction: false)
        }
    }
}
