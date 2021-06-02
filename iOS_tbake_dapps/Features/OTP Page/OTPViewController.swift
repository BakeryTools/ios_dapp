//
//  OTPViewController.swift
//  iOS_tbake_dapps
//
//  Created by Danial on 25/05/2021.
//  Copyright © 2021 Danial. All rights reserved.
//

import UIKit

protocol OTPDelegate: AnyObject {
    func doOTP()
}

class OTPViewController: UIViewController {
    @IBOutlet weak var titleLbl: UILabel!
    @IBOutlet weak var descriptionLbl: UILabel!
    @IBOutlet weak var verificationTitleLbl: UILabel!
    @IBOutlet weak var errorLbl: UILabel!
    @IBOutlet weak var resendOTPLbl: UILabel!
    
    @IBOutlet weak var parentView: UIView!
    @IBOutlet weak var OTPView: OTPFieldView!
    
    @IBOutlet weak var verificationBtn: UIButton!
    @IBOutlet weak var clearBtn: UIButton!
    
    weak var delegate: OTPDelegate?
    
    var otp_token: String?
    var targetOTPNum: String?
    var OTPString: String?
    var enteredAll: Bool?
    
    var secondsRemaining = 0
    var timer: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.setupNavigationBar()
        self.setupView()
        self.setupLbl()
        self.setupOTPView()
        self.setupBtn()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.OTPView.focusTextField()
    }
    
    deinit {
        self.timer = nil
        
        #if DEBUG
        print("🌍🌍🌍 Deinit OTPViewController 🌍🌍🌍")
        #endif
    }
    
    //MARK:- Setup View
    func setupNavigationBar(){
        let backBarButtonItem = UIBarButtonItem(title: "Kembali", style: .plain, target: nil, action: nil)
        navigationItem.backBarButtonItem = backBarButtonItem
        self.navigationController?.navigationBar.tintColor = .white
        self.navigationItem.leftBarButtonItem?.tintColor = .white
    }
    
    func setupView() {
        DispatchQueue.main.async {
            self.parentView.layer.cornerRadius = 8.0
            self.parentView.layer.masksToBounds = false
            self.parentView.layer.shadowColor = UIColor.black.cgColor
            self.parentView.layer.shadowOpacity = 0.2
            self.parentView.layer.shadowOffset = CGSize(width: 0.1, height: 0.1)
            self.parentView.layer.shadowRadius = 5.0
            self.parentView.layer.shadowPath = UIBezierPath(rect: self.parentView.bounds).cgPath
            self.parentView.layer.shouldRasterize = true
            self.parentView.layer.rasterizationScale = UIScreen.main.scale
        }
        
        self.navigationItem.title = "Kode Verifikasi"
        self.navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.white]
    }
    
    func setupLbl() {
        self.titleLbl.text = "Masukkan Kode Verifikasi"
        let tel = self.targetOTPNum?.unfoldSubSequences(limitedTo: 4).joined(separator: "-")
        self.descriptionLbl.text = "Kode verifikasi telah dikirimkan melalui SMS ke \(tel ?? "")"
        self.descriptionLbl.ChangeCertainTextColor(fullText: self.descriptionLbl.text ?? "", changeText: self.targetOTPNum ?? "", color: UIColor(named: "Label Color") ?? .black, font: UIFont(name: "LibreFranklin-Bold", size: 15))
        
        self.verificationTitleLbl.text = "Kode Verifikasi"
        
        if self.secondsRemaining > 0 {
            self.timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.countDownOTP(_:)), userInfo: nil, repeats: true)
        } else {
            self.setupResendOTPLbl()
        }
    }

    func setupOTPView() {
        DispatchQueue.main.async {
            self.OTPView.fieldsCount = 4
            self.OTPView.fieldBorderWidth = 4
            self.OTPView.defaultBorderColor = UIColor.hexStringToUIColor(hex: "#BEBEBE", 1.0)
            self.OTPView.filledBorderColor = UIColor.hexStringToUIColor(hex: "#B8226A", 1.0)
            self.OTPView.cursorColor = UIColor(named: "Label Color") ?? .black
            self.OTPView.displayType = .underlinedBottom
            self.OTPView.fieldSize = 40
            self.OTPView.separatorSpace = 15
            self.OTPView.shouldAllowIntermediateEditing = false
            self.OTPView.delegate = self
            self.OTPView.initializeUI()
        }
    }
    
    func setupBtn() {
        self.verificationBtn.setTitle("Verifikasi", for: .normal)
        
        self.verificationBtn.clipsToBounds = true
        self.verificationBtn.layer.cornerRadius = 8
        self.verificationBtn.isEnabled = false
        self.verificationBtn.backgroundColor = UIColor.hexStringToUIColor(hex: "#BFBFBF", 1.0)
        self.verificationBtn.addTarget(self, action: #selector(doVerification(_:)), for: .touchUpInside)
        
        self.clearBtn.addTarget(self, action: #selector(clearErrorUI(_:)), for: .touchUpInside)
    }
    
    func setupResendOTPLbl() {
        DispatchQueue.main.async {
            self.resendOTPLbl.text = "Belum dapat kode OTP? Kirim Ulang"
            self.resendOTPLbl.ChangeCertainTextColor(fullText: self.resendOTPLbl.text ?? "", changeText: "Kirim Ulang", color: UIColor.hexStringToUIColor(hex: "B8226A", 1.0))
            self.resendOTPLbl.isUserInteractionEnabled = true
            self.resendOTPLbl.lineBreakMode = .byWordWrapping
            let tapGesture = UITapGestureRecognizer.init(target: self, action: #selector(self.tappedOnLabel(_:)))
            tapGesture.numberOfTouchesRequired = 1
            self.resendOTPLbl.addGestureRecognizer(tapGesture)
        }
    }
    
    //MARK:- Function
    func resendOTP() {
        
    }
    
    func processOTP() {
        
        self.view.endEditing(true)
        
    }
    
    func submitOTP() {
        if self.enteredAll ?? false {
            self.processOTP()
        } else {
            DispatchQueue.main.async {
                self.errorLbl.text = "*Sila masukan kode OTP."
                self.errorLbl.isHidden = false
                self.clearBtn.isHidden = false
                self.OTPView.updateErrorUI()
            }
        }
    }
    
    //MARK:- Action Function
    @objc func clearErrorUI(_ sender: UIButton) {
        DispatchQueue.main.async {
            self.errorLbl.isHidden = true
            self.clearBtn.isHidden = true
            self.verificationBtn.isEnabled = false
            self.verificationBtn.backgroundColor = UIColor.hexStringToUIColor(hex: "#BFBFBF", 1.0)
            self.OTPView.initializeUI()
        }
    }
    
    @objc func doVerification(_ sender: UIButton) {
        self.submitOTP()
    }
    
    @objc func tappedOnLabel(_ gesture: UITapGestureRecognizer) {
      
    }
    
    @objc func countDownOTP(_ timer: Timer) {
        if self.secondsRemaining > 0 {
            DispatchQueue.main.async {
                self.resendOTPLbl.text = "Mohon tunggu \(self.secondsRemaining) detik untuk mengirim ulang"
                self.resendOTPLbl.ChangeCertainTextColor(fullText: self.resendOTPLbl.text ?? "", changeText: "\(self.secondsRemaining) detik", color: UIColor(named: "Label Color") ?? .black, font: UIFont(name: "LibreFranklin-SemiBold", size: 14))
            }
            self.secondsRemaining -= 1
        }else{
            self.secondsRemaining = 0
            self.setupResendOTPLbl()
            
            timer.invalidate()
        }
    }
    
    @objc func countDownOTPLimit(_ timer: Timer) {
        if self.secondsRemaining > 0 {
            self.secondsRemaining -= 1
        }else{
            self.secondsRemaining = 0
            self.setupResendOTPLbl()
            
            timer.invalidate()
        }
    }
}

// MARK: - OTPFieldViewDelegate Delegate
extension OTPViewController: OTPFieldViewDelegate {
    func hasEnteredAllOTP(hasEnteredAll hasEntered: Bool) -> Bool {
        if hasEntered {
            self.processOTP()
            DispatchQueue.main.async {
                self.verificationBtn.isEnabled = true
                self.verificationBtn.backgroundColor = UIColor.hexStringToUIColor(hex: "#B3286D", 1.0)
            }
        } else {
            DispatchQueue.main.async {
                self.errorLbl.isHidden = true
                self.clearBtn.isHidden = true
                self.verificationBtn.isEnabled = false
                self.verificationBtn.backgroundColor = UIColor.hexStringToUIColor(hex: "#BFBFBF", 1.0)
            }
        }
        
        self.enteredAll = hasEntered
        return false
    }
    
    func shouldBecomeFirstResponderForOTP(otpTextFieldIndex index: Int) -> Bool {
        DispatchQueue.main.async { self.errorLbl.isHidden = true; self.clearBtn.isHidden = true }
        return true
    }
    
    func enteredOTP(otp otpString: String) {
        self.OTPString = otpString
    }
}
