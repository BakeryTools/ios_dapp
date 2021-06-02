//
//  ProfileTableViewCell.swift
//  iOS_tbake_dapps
//
//  Created by Danial on 25/05/2021.
//

import UIKit

class ProfileTableViewCell: UITableViewCell {

    @IBOutlet weak var parentView: UIView!
    @IBOutlet weak var durationView: UIView!
    
    @IBOutlet weak var unstakeLbl: UILabel!
    @IBOutlet weak var durationLbl: UILabel!
    @IBOutlet weak var amountStakingLbl: UILabel!
    @IBOutlet weak var pastDateStakingLbl: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.setupView()
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
            
            self.durationView.layer.borderWidth = 1.0
            self.durationView.layer.borderColor = UIColor.hexStringToUIColor(hex: "#B45618", 1.0).cgColor
            self.durationView.layer.cornerRadius = 8.0
        }
    }
    
    func configureCell(process: String, duration: String, amount: String, pastDate: String) {
        self.unstakeLbl.text = process
        self.durationLbl.text = duration
        self.amountStakingLbl.text = amount
        self.pastDateStakingLbl.text = pastDate
    }
}
