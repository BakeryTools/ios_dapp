//
//  HomepageViewController.swift
//  iOS_tbake_dapps
//
//  Created by Danial on 24/05/2021.
//

import UIKit

class HomepageViewController: UIViewController {
    
    @IBOutlet weak var searchBar: UISearchBar!
    
    @IBOutlet weak var lockStakingLbl: UILabel!
    @IBOutlet weak var descriptionTitleLbl: UILabel!
    @IBOutlet weak var descriptionLbl: UILabel!
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var descriptionView: UIView!
    
    var duration: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.setupLbl()
        self.setupView()
        self.setupCell()
        self.setupSearchBar()
        self.setupNavigationBar()
    }
    
    //MARK:- Setup View
    func setupLbl() {
        self.lockStakingLbl.text = "Locked Staking"
        self.descriptionTitleLbl.text = "Welcome to Bakery Tools"
        self.descriptionLbl.text = "Bakerytools is a central hub & trading tool for Binance chain pairs & pool explorer and a hotspot for Private and pre-sale listings."
    }
    
    func setupView() {
        self.descriptionView.layer.cornerRadius = 8.0
    }
    
    func setupCell() {
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.tableView.register(UINib(nibName: "HomepageTableViewCell", bundle: nil), forCellReuseIdentifier: "HomepageTableViewCell")
        self.tableView.tableFooterView = UIView()
    }

    func setupSearchBar() {
        self.searchBar.placeholder = "Choose/Search Coin"
    }
    
    func setupNavigationBar() {
        self.title = "Bakery Tools"
        
        let leftButton = UIButton(type: .custom)
        leftButton.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        leftButton.contentHorizontalAlignment = .left
        leftButton.setImage(UIImage(named: "icon_profile"), for: .normal)
        leftButton.addTarget(self, action: #selector(self.goToProfile(_:)), for: .touchUpInside)
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: leftButton)
        
        let rightButton = UIButton(type: .custom)
        rightButton.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        rightButton.contentHorizontalAlignment = .right
        rightButton.setImage(UIImage(named: "icon_question_mark"), for: .normal)
        rightButton.addTarget(self, action: #selector(self.goToTermCondition(_:)), for: .touchUpInside)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: rightButton)
        
        let backBarButtonItem = UIBarButtonItem(title: "Back", style: .plain, target: nil, action: nil)
        navigationItem.backBarButtonItem = backBarButtonItem
        self.navigationController?.navigationBar.tintColor = UIColor.hexStringToUIColor(hex: "#A05314", 1.0)
        self.navigationItem.leftBarButtonItem?.tintColor = UIColor.hexStringToUIColor(hex: "#A05314", 1.0)
    }
    
    //MARK:- Action Function
    @objc func goToProfile(_ sender: UIButton) {
        let profilePage = ProfilePageViewController(nibName: "ProfilePageViewController", bundle: nil)
        self.navigationController?.pushViewController(profilePage, animated: true)
    }
    
    @objc func goToTermCondition(_ sender: UIButton) {
        
    }
}

//MARK:- UITableViewDataSource, UITableViewDelegate
extension HomepageViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return screenHeight
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "HomepageTableViewCell", for: indexPath) as? HomepageTableViewCell else { return UITableViewCell() }
        cell.selectionStyle = .none
        cell.delegate = self
        cell.configureCell(tokenTitle: "TBake", aprTotal: "30,000 TBAKE")
        
        return cell
    }
}

//MARK:- HomepageTableViewCellDelegate
extension HomepageViewController: HomepageTableViewCellDelegate {
    func doSelectDuration(duration: String) {
        self.duration = duration
    }
    
    func doStacking() {
        DispatchQueue.main.async {
            let sceneDelegate = self.view.window?.windowScene?.delegate as? SceneDelegate
            let stackingPage = StakingPageViewController(nibName: "StakingPageViewController", bundle: nil)
            stackingPage.duration = self.duration ?? "30"
            let nib = UINavigationController(rootViewController: stackingPage)
            nib.modalPresentationStyle = .fullScreen
            nib.modalTransitionStyle = .crossDissolve
            sceneDelegate?.getTopMostViewController()?.present(nib, animated: true, completion: nil)
        }
    }
}
