//
//  SettingTableViewController.swift
//  iOS_tbake_dapps
//
//  Created by Danial on 25/05/2021.
//

import UIKit

class SettingTableViewController: UITableViewController {
        
    var gotUpdate: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //initialize code
        self.setupCell()
        self.setupView()
        self.setupNavigationBar()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
    
        //check update version
        checkAppUpdate() {
            self.gotUpdate = true
            DispatchQueue.main.async { self.tableView.reloadData() }
        }
    }

    deinit {
        #if DEBUG
        print("🌍🌍🌍 Deinit SettingTableViewController 🌍🌍🌍")
        #endif
    }
    
    //MARK:- Setup View
    func setupNavigationBar() {
        self.navigationItem.hidesBackButton = true
        let newButton = UIButton(type: .custom)
        newButton.frame = CGRect(x: 0, y: 0, width: 40, height: 30)
        newButton.contentHorizontalAlignment = .left
        newButton.setImage(UIImage(named: "icon_close_dark"), for: .normal)
        newButton.addTarget(self, action: #selector(self.doBackButton(_:)), for: .touchUpInside)
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: newButton)
        
        self.navigationItem.title = "Setting"
        self.navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.hexStringToUIColor(hex: "#A05314", 1.0)]
    }
    
    func setupView(){
        self.tableView.tableFooterView = UIView()
    }
    
    //MARK:- Setup Table View Cell
    func setupCell() {
        self.tableView.register(UINib(nibName: "LanguageTableViewCell", bundle: nil), forCellReuseIdentifier: "LanguageTableViewCell")
        self.tableView.register(UINib(nibName: "DarkmodeTableViewCell", bundle: nil), forCellReuseIdentifier: "DarkmodeTableViewCell")
        self.tableView.register(UINib(nibName: "AboutDeviceTableViewCell", bundle: nil), forCellReuseIdentifier: "AboutDeviceTableViewCell")
    }
    
    //MARK:- Action Function
    @objc func doBackButton(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 2
    }

    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return screenHeight
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.row {
        case 0:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "DarkmodeTableViewCell", for: indexPath) as? DarkmodeTableViewCell else { return UITableViewCell() }
            cell.selectionStyle = .none
            cell.delegate = self
            cell.configureCell(string: "Darkmode")
            return cell
        default:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "AboutDeviceTableViewCell", for: indexPath) as? AboutDeviceTableViewCell else { return UITableViewCell() }
            cell.selectionStyle = .none
            cell.delegate = self
            cell.configureCell(string: "About Device", gotUpdate: self.gotUpdate)
            return cell
        }
    }
}

// MARK: - DarkmodeDelegate Delegate
extension SettingTableViewController: DarkmodeDelegate {
    // set darkmode
    func setDarkMode(isDark: Bool) {
        let sceneDelegate = self.view.window?.windowScene?.delegate as? SceneDelegate
        sceneDelegate?.setDarkMode(isDark: isDark)
    }
}

// MARK: - AboutDeviceDelegate Delegate
extension SettingTableViewController: AboutDeviceDelegate {
    // go to App Store for update
    func goToAppStore() {
        guard let url = NSURL(string: "itms-apps://itunes.apple.com/my/app/recommend-my-home-services/id1141029260") else { return }
        UIApplication.shared.open( url as URL, options: [:], completionHandler: nil)
    }
    
    func refreshRow(indexPath: IndexPath) {
        DispatchQueue.main.async { self.tableView.reloadRows(at: [indexPath], with: .none) }
    }
}
