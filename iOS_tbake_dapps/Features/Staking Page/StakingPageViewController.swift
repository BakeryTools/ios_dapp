//
//  StakingPageViewController.swift
//  iOS_tbake_dapps
//
//  Created by Danial on 24/05/2021.
//

import UIKit

class StakingPageViewController: UIViewController {

    @IBOutlet weak var descriptionView: UIView!
    @IBOutlet weak var typeView: UIStackView!
    @IBOutlet weak var amountView: UIView!
    @IBOutlet weak var durationView1: UIView!
    @IBOutlet weak var durationView2: UIView!
    @IBOutlet weak var durationView3: UIView!
    @IBOutlet weak var separatorView: UIView!
    
    @IBOutlet weak var lockTextField: UITextField!
    
    @IBOutlet weak var descriptionLbl: UILabel!
    @IBOutlet weak var typeLbl: UILabel!
    @IBOutlet weak var typeDataLbl: UILabel!
    @IBOutlet weak var durationLbl: UILabel!
    @IBOutlet weak var durationLbl1: UILabel!
    @IBOutlet weak var durationLbl2: UILabel!
    @IBOutlet weak var durationLbl3: UILabel!
    @IBOutlet weak var lockLbl: UILabel!
    @IBOutlet weak var balanceLbl: UILabel!
    @IBOutlet weak var lockAmountTitleLbl: UILabel!
    @IBOutlet weak var minimumLbl: UILabel!
    @IBOutlet weak var maximumLbl: UILabel!
    
    @IBOutlet weak var summaryLbl: UILabel!
    @IBOutlet weak var stakeDateLbl: UILabel!
    @IBOutlet weak var stakeDateDataLbl: UILabel!
    @IBOutlet weak var valueDateLbl: UILabel!
    @IBOutlet weak var valueDateDataLbl: UILabel!
    @IBOutlet weak var redemptionDateLbl: UILabel!
    @IBOutlet weak var redemptionDateDataLbl: UILabel!
    @IBOutlet weak var estimateInterestLbl: UILabel!
    @IBOutlet weak var estimateInterestDataLbl: UILabel!
    
    @IBOutlet weak var agreementView: UIView!
    @IBOutlet weak var agreementCheckboxBtn: UIButton!
    @IBOutlet weak var agreementLbl: UILabel!
    
    @IBOutlet weak var maxBtn: UIButton!
    @IBOutlet weak var submitBtn: UIButton!
    
    var duration = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.setupNavigationBar()
        self.setupLbl()
        self.setupView()
        self.setupBtn()
        self.setupTextField()
    }

    //MARK:- Setup View
    func setupNavigationBar() {
        let nib = UINib(nibName: "TitleView", bundle: nil)
        let myNibView = nib.instantiate(withOwner: self, options: nil)[0] as? TitleView
        myNibView?.titleNameLbl.text = "TBake"
        
        self.navigationItem.titleView = myNibView
        
        
        self.navigationItem.hidesBackButton = true
        let newButton = UIButton(type: .custom)
        let backImage = UIImage(named: "icon_close_dark")
        newButton.setImage(backImage, for: .normal)
        newButton.addTarget(self, action: #selector(doDismiss(_:)), for: .touchUpInside)
        let newBackButton = UIBarButtonItem(customView: newButton)
        self.navigationItem.leftBarButtonItem = newBackButton
    }
    
    func setupLbl() {
        self.descriptionLbl.text = "Locked staking offers you to lock your cryptocurrencies over a predetermined period of time to obtain returns. The longer you lock them, the higher the return you will get. You can choose between periods of 30/60/90 days."
        self.typeLbl.text = "Type"
        self.durationLbl.text = "Duration"
        
        self.durationLbl1.text = "30"
        self.durationLbl.textColor = self.duration == "30" ? UIColor.hexStringToUIColor(hex: "#B45618", 1.0) : UIColor(named: "LabelColor")
        
        self.durationLbl2.text = "60"
        self.durationLbl2.textColor = self.duration == "60" ? UIColor.hexStringToUIColor(hex: "#B45618", 1.0) : UIColor(named: "LabelColor")
        
        self.durationLbl3.text = "90"
        self.durationLbl3.textColor = self.duration == "90" ? UIColor.hexStringToUIColor(hex: "#B45618", 1.0) : UIColor(named: "LabelColor")
        
        self.lockLbl.text = "Lock Amount"
        self.typeDataLbl.text = "Locked"
        
        self.lockAmountTitleLbl.text = "Lock Amount Limitation"
        self.minimumLbl.text = "Minimum: 30000 TBAKE"
        self.maximumLbl.text = "Maximum: N/A"
        
        self.summaryLbl.text = "Summary"
        self.stakeDateLbl.text = "Stake Date"
        self.valueDateLbl.text = "Value Date"
        self.redemptionDateLbl.text = "Redemption Date"
        self.estimateInterestLbl.text = "Estimated Interest"
        
        //need to assign data
        self.stakeDateDataLbl.text = "2021-05-17 19:40"
        self.valueDateDataLbl.text = "2021-05-18 00:00"
        self.redemptionDateDataLbl.text = "2021-06-18 00:00"
        self.estimateInterestDataLbl.text = "900.00 TBAKE"
        ///
        
        self.agreementLbl.text = "I have read and I agree to Bakery Tools Agreement"
        self.agreementLbl.ChangeCertainTextColor(fullText: self.agreementLbl.text ?? "", changeText: "Bakery Tools Agreement", color: UIColor.hexStringToUIColor(hex: "#A05314", 1.0))
        self.agreementLbl.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer.init(target: self, action: #selector(tappedOnLabel(_:)))
        tapGesture.numberOfTouchesRequired = 1
        self.agreementLbl.addGestureRecognizer(tapGesture)
    }
    
    func setupView() {
        self.descriptionView.layer.cornerRadius = 8.0
        self.typeView.layer.cornerRadius = 8.0
        
        self.typeView.layer.borderWidth = 1.0
        self.typeView.layer.borderColor = UIColor.hexStringToUIColor(hex: "#BBBBBB", 1.0).cgColor
        self.typeView.layer.cornerRadius = 8.0
        
        self.durationView1.layer.borderWidth = 1.0
        self.durationView1.layer.borderColor = UIColor.hexStringToUIColor(hex: self.duration == "30" ? "#B45618" : "#7B7B7B", 1.0).cgColor
        self.durationView1.layer.cornerRadius = 8.0
        
        self.durationView2.layer.borderWidth = 1.0
        self.durationView2.layer.borderColor = UIColor.hexStringToUIColor(hex: self.duration == "60" ? "#B45618" : "#7B7B7B", 1.0).cgColor
        self.durationView2.layer.cornerRadius = 8.0
        
        self.durationView3.layer.borderWidth = 1.0
        self.durationView3.layer.borderColor = UIColor.hexStringToUIColor(hex: self.duration == "90" ? "#B45618" : "#7B7B7B", 1.0).cgColor
        self.durationView3.layer.cornerRadius = 8.0
        
        self.amountView.layer.borderWidth = 1.0
        self.amountView.layer.borderColor = UIColor.hexStringToUIColor(hex: "#7B7B7B", 1.0).cgColor
        self.amountView.layer.cornerRadius = 8.0
        
        self.separatorView.layer.borderWidth = 1.0
        self.separatorView.layer.borderColor = UIColor.hexStringToUIColor(hex: "#E0E0E0", 1.0).cgColor
        
        self.agreementView.layer.cornerRadius = 8.0
    }
    
    func setupBtn() {
        self.agreementCheckboxBtn.addTarget(self, action: #selector(self.doCheckbox(_:)), for: .touchUpInside)
        self.submitBtn.layer.cornerRadius = 8.0
        self.submitBtn.addTarget(self, action: #selector(self.doSubmit(_:)), for: .touchUpInside)
    }
    
    func setupTextField() {
        self.lockTextField.placeholder = "Please enter the amount"
    }
    
    func configureData() {
        self.balanceLbl.text = "Balance: 3000"
    }
    
    //MARK:- Action Function
    @objc func doDismiss(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func doCheckbox(_ sender: UIButton) {
        self.agreementCheckboxBtn.isSelected = !self.agreementCheckboxBtn.isSelected
        
        switch self.agreementCheckboxBtn.isSelected {
        case true:
            self.agreementCheckboxBtn.setImage(UIImage(named: "icon_checked_box"), for: .normal)
        default:
            self.agreementCheckboxBtn.setImage(UIImage(named: "icon_unchecked_box"), for: .normal)
        }
    }
    
    @objc func doSubmit(_ sender: UIButton) {
    
    }
    
    @objc func tappedOnLabel(_ gesture: UITapGestureRecognizer) {
        guard let text = self.agreementLbl.text else { return }
        let textRange = (text as NSString).range(of: "Bakery Tools Agreement")
        if gesture.didTapAttributedTextInLabel(label: self.agreementLbl, inRange: textRange) {
            print("Agreement Tapped")
        }
    }
}
