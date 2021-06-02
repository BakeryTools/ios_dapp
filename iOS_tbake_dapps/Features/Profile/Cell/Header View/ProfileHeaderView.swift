//
//  ProfileHeaderView.swift
//  iOS_tbake_dapps
//
//  Created by Danial on 26/05/2021.
//

import UIKit

class ProfileHeaderView: UIView {

    @IBOutlet weak var titleLbl: UILabel!
    @IBOutlet weak var dataLbl: UILabel!
    
    @IBOutlet weak var parentView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.setupView()
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
    
    //MARK:- Configure Cell
    func configureCell(titleString: String, dataString: String){
        self.titleLbl.text = titleString
        self.dataLbl.text = dataString
    }
}
