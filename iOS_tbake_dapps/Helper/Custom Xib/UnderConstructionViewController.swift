//
//  UnderConstructionViewController.swift
//  iOS_tbake_dapps
//
//  Created by Danial on 29/07/2021.
//

import UIKit

protocol UnderConstructionViewControllerDelegate: AnyObject {
    func doDismiss()
}

class UnderConstructionViewController: UIViewController {

    @IBOutlet weak var parentView: UIView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var descriptionLbl: UILabel!
    @IBOutlet weak var confirmBtn: UIButton!
    
    weak var delegate: UnderConstructionViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.setupView()
        self.setupBtn()
        self.setupLbl()
    }

    deinit {
        #if DEBUG
        print("🌍🌍🌍 Deinit UnderConstructionViewController 🌍🌍🌍")
        #endif
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        self.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Function
    func setupView() {
        self.parentView.layer.cornerRadius = 8.0
        
        //setup image gif
        DispatchQueue.main.async {
            self.imageView.loadGif(asset: "maintenance_GIF")
        }
    }
    
    func setupBtn() {
        self.confirmBtn.layer.cornerRadius = 8.0
        self.confirmBtn.setTitle(R.string.localizable.oK(), for: .normal)
        self.confirmBtn.addTarget(self, action: #selector(doDismiss(_:)), for: .touchUpInside)
    }
    
    func setupLbl() {
        self.descriptionLbl.text = R.string.localizable.underConstruction()
    }
    
    // MARK: - Action Function
    @objc func doDismiss(_ sender: UIButton) {
        self.delegate?.doDismiss()
        self.dismiss(animated: true, completion: nil)
    }
}
