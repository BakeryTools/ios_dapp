//
//  HomepageTableViewCell.swift
//  iOS_tbake_dapps
//
//  Created by Danial on 24/05/2021.
//

import UIKit

protocol HomepageTableViewCellDelegate: AnyObject {
    func doStacking()
    func doSelectDuration(duration: String)
}

class HomepageTableViewCell: UITableViewCell {

    @IBOutlet weak var parentView: UIView!
    @IBOutlet weak var logoImgView: UIImageView!
    
    @IBOutlet weak var tokenTitleLbl: UILabel!
    @IBOutlet weak var dayLbl: UILabel!
    @IBOutlet weak var aprLbl: UILabel!
    @IBOutlet weak var aprDataLbl: UILabel!
    @IBOutlet weak var durationLbl1: UILabel!
    @IBOutlet weak var durationLbl2: UILabel!
    @IBOutlet weak var durationLbl3: UILabel!
    
    @IBOutlet weak var durationView1: UIView!
    @IBOutlet weak var durationView2: UIView!
    @IBOutlet weak var durationView3: UIView!
    
    @IBOutlet weak var stackingBtn: UIButton!
    
    weak var delegate: HomepageTableViewCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.setupView()
        self.setupBtn()
        self.setupLbl()
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
            
            self.durationView1.layer.borderWidth = 1.0
            self.durationView1.layer.borderColor = UIColor.hexStringToUIColor(hex: "#B45618", 1.0).cgColor
            self.durationLbl1.textColor = UIColor.hexStringToUIColor(hex: "#B45618", 1.0)
            
            self.durationView1.layer.cornerRadius = 8.0
            
            self.durationView2.layer.borderWidth = 1.0
            self.durationView2.layer.borderColor = UIColor.hexStringToUIColor(hex: "#7B7B7B", 1.0).cgColor
            self.durationView2.layer.cornerRadius = 8.0
            
            self.durationView3.layer.borderWidth = 1.0
            self.durationView3.layer.borderColor = UIColor.hexStringToUIColor(hex: "#7B7B7B", 1.0).cgColor
            self.durationView3.layer.cornerRadius = 8.0
        }
        
        let tap1 = UITapGestureRecognizer(target: self, action: #selector(self.doSelectDuration(_:)))
        self.durationView1.tag = 30
        self.durationView1.addGestureRecognizer(tap1)
        
        let tap2 = UITapGestureRecognizer(target: self, action: #selector(self.doSelectDuration(_:)))
        self.durationView2.tag = 60
        self.durationView2.addGestureRecognizer(tap2)
        
        let tap3 = UITapGestureRecognizer(target: self, action: #selector(self.doSelectDuration(_:)))
        self.durationView3.tag = 90
        self.durationView3.addGestureRecognizer(tap3)
        
    }
    
    func setupBtn() {
        self.stackingBtn.layer.cornerRadius = 8.0
        self.stackingBtn.setTitle("Stack Now", for: .normal)
        self.stackingBtn.addTarget(self, action: #selector(self.doStacking(_:)), for: .touchUpInside)
    }
    
    func setupLbl() {
        self.durationLbl1.text = "30"
        self.durationLbl2.text = "60"
        self.durationLbl3.text = "90"
        
        self.dayLbl.text = "Days"
        self.aprLbl.text = "Minimum locked Amount"
    }
    
    func configureCell(tokenTitle: String, aprTotal: String) {
        self.tokenTitleLbl.text = tokenTitle
        self.aprDataLbl.text = aprTotal
    }
    
    //MARK:- Action Function
    @objc func doStacking(_ sender: UIButton) {
        self.delegate?.doStacking()
    }
    
    @objc func doSelectDuration(_ sender: UITapGestureRecognizer) {
        switch sender.view?.tag {
        case 30:
            self.durationView1.layer.borderColor = UIColor.hexStringToUIColor(hex: "#B45618", 1.0).cgColor
            self.durationView2.layer.borderColor = UIColor.hexStringToUIColor(hex: "#7B7B7B", 1.0).cgColor
            self.durationView3.layer.borderColor = UIColor.hexStringToUIColor(hex: "#7B7B7B", 1.0).cgColor
            
            self.durationLbl1.textColor = UIColor.hexStringToUIColor(hex: "#B45618", 1.0)
            self.durationLbl2.textColor = UIColor(named: "LabelColor")
            self.durationLbl3.textColor = UIColor(named: "LabelColor")
        case 60:
            self.durationView1.layer.borderColor = UIColor.hexStringToUIColor(hex: "#7B7B7B", 1.0).cgColor
            self.durationView2.layer.borderColor = UIColor.hexStringToUIColor(hex: "#B45618", 1.0).cgColor
            self.durationView3.layer.borderColor = UIColor.hexStringToUIColor(hex: "#7B7B7B", 1.0).cgColor
            
            self.durationLbl1.textColor = UIColor(named: "LabelColor")
            self.durationLbl2.textColor = UIColor.hexStringToUIColor(hex: "#B45618", 1.0)
            self.durationLbl3.textColor = UIColor(named: "LabelColor")
        default:
            self.durationView1.layer.borderColor = UIColor.hexStringToUIColor(hex: "#7B7B7B", 1.0).cgColor
            self.durationView2.layer.borderColor = UIColor.hexStringToUIColor(hex: "#7B7B7B", 1.0).cgColor
            self.durationView3.layer.borderColor = UIColor.hexStringToUIColor(hex: "#B45618", 1.0).cgColor
            
            self.durationLbl1.textColor = UIColor(named: "LabelColor")
            self.durationLbl2.textColor = UIColor(named: "LabelColor")
            self.durationLbl3.textColor = UIColor.hexStringToUIColor(hex: "#B45618", 1.0)
        }
        
        self.delegate?.doSelectDuration(duration: "\(sender.view?.tag ?? 0)")
    }
}
