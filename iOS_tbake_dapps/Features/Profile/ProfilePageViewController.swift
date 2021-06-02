//
//  ProfilePageViewController.swift
//  iOS_tbake_dapps
//
//  Created by Danial on 24/05/2021.
//

import UIKit

class ProfilePageViewController: UIViewController {

    @IBOutlet weak var emailView: UIView!
    
    @IBOutlet weak var emailLbl: UILabel!
    @IBOutlet weak var verifyStatusLbl: UILabel!
    @IBOutlet weak var userIDLbl: UILabel!
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.setupView()
        self.setupLbl()
        self.setupCell()
        self.setupNavigationBar()
    }


   //MARK:- Setup View
    func setupView() {
        self.emailView.layer.masksToBounds = false
        self.emailView.layer.shadowColor = UIColor.lightGray.cgColor
        self.emailView.layer.shadowOpacity = 0.5
        self.emailView.layer.shadowOffset = CGSize(width: 0.2, height: 0.2)
        self.emailView.layer.shadowRadius = 5.0
    }
    
    func setupLbl() {
        self.emailLbl.text = "Em***@gmail.com"
        self.verifyStatusLbl.text = "Verified"
        self.userIDLbl.text = "User ID:00000"
    }
    
    func setupCell() {
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.tableView.register(UINib(nibName: "WalletConnectTableViewCell", bundle: nil), forCellReuseIdentifier: "WalletConnectTableViewCell")
        self.tableView.register(UINib(nibName: "ProfileTableViewCell", bundle: nil), forCellReuseIdentifier: "ProfileTableViewCell")
        self.tableView.tableFooterView = UIView()
    }

    func setupNavigationBar() {
        self.title = "Bakery Tools"
        
        let rightButton = UIButton(type: .custom)
        rightButton.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        rightButton.contentHorizontalAlignment = .right
        rightButton.setImage(UIImage(named: "icon_setting"), for: .normal)
        rightButton.addTarget(self, action: #selector(self.goToSetting(_:)), for: .touchUpInside)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: rightButton)
    }
    
    //MARK:- Action Function
    @objc func goToSetting(_ sender: UIButton) {
        let nib = SettingTableViewController(nibName: "SettingTableViewController", bundle: nil)
        let navBarOnModal: UINavigationController = UINavigationController(rootViewController: nib)
        navBarOnModal.modalPresentationStyle = .fullScreen
        self.present(navBarOnModal, animated: true, completion: nil)
    }
}

//MARK:- UITableViewDataSource, UITableViewDelegate
extension ProfilePageViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
        default:
            return 2
        }
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return screenHeight
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch section {
        case 0:
            return CGFloat.leastNonzeroMagnitude
        default:
            return 50
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        switch section {
        case 0:
            return nil
        default:
            let nib = UINib(nibName: "ProfileHeaderView", bundle: nil)
            let myNibView = nib.instantiate(withOwner: self, options: nil)[0] as? ProfileHeaderView
            myNibView?.configureCell(titleString: "Recent Activity", dataString: "Locked Staking")
            return myNibView
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        switch indexPath.section {
        case 0:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "WalletConnectTableViewCell", for: indexPath) as? WalletConnectTableViewCell else { return UITableViewCell() }
            cell.selectionStyle = .none
            cell.delegate = self
            
            return cell
        default:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "ProfileTableViewCell", for: indexPath) as? ProfileTableViewCell else { return UITableViewCell() }
            cell.selectionStyle = .none
            if indexPath.row == 0 {
                cell.configureCell(process: "Unstake", duration: "90", amount: "30,900 TBAKE", pastDate: "2021-05-17 18:55:59")
            }else{
                cell.configureCell(process: "Stake", duration: "90", amount: "30,000 TBAKE", pastDate: "2021-02-17 18:55:59")
            }
            
            return cell
        }
    }
}

extension ProfilePageViewController: WalletConnectTableViewCellDelegate {
    func doConnectWallet() {
        print("Connect Wallet")
    }
}
