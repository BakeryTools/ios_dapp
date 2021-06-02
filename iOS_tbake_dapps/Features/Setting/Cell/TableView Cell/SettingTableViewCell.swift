//
//  SettingTableViewCell.swift
//  iOS_tbake_dapps
//
//  Created by Danial on 25/05/2021.
//

import UIKit

class SettingTableViewCell: UITableViewCell {
    
    @IBOutlet weak var titleLbl: UILabel!
    @IBOutlet weak var dataLbl: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func configureCell(title: String, data: String){
        self.titleLbl.text = title
        self.dataLbl.text = data
    }
}
