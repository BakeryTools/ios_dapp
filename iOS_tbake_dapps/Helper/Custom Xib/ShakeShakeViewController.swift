//
//  ShakeShakeViewController.swift
//  recommend-customer-ios
//
//  Created by Danial on 04/05/2020.
//  Copyright © 2020 Danial. All rights reserved.
//

import UIKit

class ShakeShakeViewController: UIViewController {

    @IBOutlet weak var parentView: UIView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var descriptionLbl: UILabel!
    @IBOutlet weak var confirmBtn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.setupView()
        self.setupBtn()
        self.setupLbl()
    }

    deinit {
        #if DEBUG
        print("🌍🌍🌍 Deinit ShakeShakeViewController 🌍🌍🌍")
        #endif
    }
    
    // MARK: - Function
    func setupView() {
        self.parentView.layer.cornerRadius = 8.0
        
        //setup image gif
        DispatchQueue.main.async {
            self.imageView.loadGif(asset: "shake_GIF")
        }
    }
    
    func setupBtn() {
        self.confirmBtn.layer.cornerRadius = 8.0
        self.confirmBtn.setTitle(R.string.localizable.oK(), for: .normal)
        self.confirmBtn.addTarget(self, action: #selector(doDismiss(_:)), for: .touchUpInside)
    }
    
    func setupLbl() {
        self.descriptionLbl.text = R.string.localizable.sendBugByShake()
    }
    
    // MARK: - Action Function
    @objc func doDismiss(_ sender: UIButton) {
        setShakeNib(true)
        self.dismiss(animated: true, completion: nil)
    }
}
