//
//  DarkmodeTableViewCell.swift
//  iOS_tbake_dapps
//
//  Created by Danial on 25/05/2021.
//  Copyright © 2021 Danial. All rights reserved.
//

import UIKit

protocol DarkmodeDelegate: AnyObject {
    func setDarkMode(isDark: Bool)
}

class DarkmodeTableViewCell: UITableViewCell {

    @IBOutlet weak var titleLbl: UILabel!
    @IBOutlet weak var darkModeSwitch: UISwitch!
    
    weak var delegate: DarkmodeDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.setupSwitch()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func setupSwitch() {
        self.darkModeSwitch.addTarget(self, action: #selector(self.preferencesToggled(_:)), for: .valueChanged)
        
        // set dark mode according to user preferences
        let darkMode = UserDefaults.standard.bool(forKey: "darkMode")
        self.darkModeSwitch.isOn = darkMode ? true : false
    }
    
    func configureCell(string: String?){
        self.titleLbl.text = string ?? ""
    }
    
    // MARK: - Event Actions
    @objc func preferencesToggled(_ sender: UISwitch) {
        UserDefaults.standard.set(sender.isOn ? true : false, forKey: "darkMode")
        self.delegate?.setDarkMode(isDark: sender.isOn)
    }
}
