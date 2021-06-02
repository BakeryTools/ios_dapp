//
//  WalletConnectTableViewCell.swift
//  iOS_tbake_dapps
//
//  Created by Danial on 25/05/2021.
//

import UIKit

protocol WalletConnectTableViewCellDelegate: AnyObject {
    func doConnectWallet()
}
class WalletConnectTableViewCell: UITableViewCell {

    @IBOutlet weak var parentView: UIView!
    
    @IBOutlet weak var connectTitleLbl: UILabel!
    @IBOutlet weak var connectNowBtn: UIButton!
    
    
    weak var delegate: WalletConnectTableViewCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.setupView()
        self.setupLbl()
        self.setupBtn()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    //MARK:- Setup View
    func setupView() {
        DispatchQueue.main.async {
            self.parentView.layer.cornerRadius = 10.0
            self.parentView.layer.masksToBounds = false
            self.parentView.layer.shadowColor = UIColor.lightGray.cgColor
            self.parentView.layer.shadowOpacity = 0.5
            self.parentView.layer.shadowOffset = CGSize(width: 0.2, height: 0.2)
            self.parentView.layer.shadowRadius = 5.0
        }
    }
    
    func setupLbl() {
        self.connectTitleLbl.text = "Connect your Metamask wallet or Trust Wallet"
    }
    
    func setupBtn() {
        self.connectNowBtn.setTitle("Connect Now", for: .normal)
        self.connectNowBtn.layer.borderWidth = 1.0
        self.connectNowBtn.layer.borderColor = UIColor.hexStringToUIColor(hex: "#B45618", 1.0).cgColor
        self.connectNowBtn.layer.cornerRadius = 8.0
        self.connectNowBtn.addTarget(self, action: #selector(self.doConnectWallet(_:)), for: .touchUpInside)
        self.connectNowBtn.titleLabel?.lineBreakMode = .byWordWrapping
        
    }
    
    //MARK:- Action Function
    @objc func doConnectWallet(_ sender: UIButton) {
        self.delegate?.doConnectWallet()
    }
}
