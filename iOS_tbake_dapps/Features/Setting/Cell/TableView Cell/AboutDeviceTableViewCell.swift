//
//  AboutDeviceTableViewCell.swift
//  iOS_tbake_dapps
//
//  Created by Danial on 25/05/2021.
//  Copyright © 2021 Danial. All rights reserved.
//

import UIKit

protocol AboutDeviceDelegate: AnyObject  {
    func goToAppStore()
}

class AboutDeviceTableViewCell: UITableViewCell {

    @IBOutlet weak var titleLbl: UILabel!
    @IBOutlet weak var mobileIDLbl: UILabel!
    @IBOutlet weak var iosVersionLbl: UILabel!
    @IBOutlet weak var appVersionLbl: UILabel!
    @IBOutlet weak var updateBtn: UIButton!
    @IBOutlet weak var iconImgView: UIImageView!
    
    weak var delegate: AboutDeviceDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
        self.setupView()
    }
    
    func setupView() {
        if let mobileId = UIDevice.current.identifierForVendor?.uuidString {
            self.mobileIDLbl.text = "Mobile ID : [mobileID]".replacingOccurrences(of: "[mobileID]", with: mobileId)
        }
        
        self.iosVersionLbl.text = "iOS Version : [deviceID]".replacingOccurrences(of: "[deviceID]", with: UIDevice.current.systemVersion)
        
        if let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            self.appVersionLbl.text = "App Version : v[appVersion]".replacingOccurrences(of: "[appVersion]", with: appVersion)
        }
    
        self.updateBtn.layer.cornerRadius = 8
        self.updateBtn.setTitle("Update Now", for: .normal)
        self.updateBtn.addTarget(self, action: #selector(doButtonUpdate(_:)), for: .touchUpInside)
    }
    
    func configureCell(string: String?, gotUpdate: Bool?){
        self.titleLbl.text = string ?? ""
        
        DispatchQueue.main.async {
            self.iconImgView.image = (gotUpdate ?? false) ? UIImage(named: "icon_alert") : UIImage(named: "icon_checked")
            self.updateBtn.isHidden = (gotUpdate ?? false) ? false : true
        }
    }
    
    @objc func doButtonUpdate(_ sender: UIButton) {
        self.delegate?.goToAppStore()
    }
}
