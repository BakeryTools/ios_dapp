//
// Created by James Sangalli on 8/12/18.
//

import Foundation
import UIKit
import StatefulViewController

protocol MyDappsViewControllerDelegate: AnyObject {
    func doRefresh(inViewController viewController: MyDappsViewController)
    func didTapToSelect(dapp: Bookmark, inViewController viewController: MyDappsViewController)
    func delete(dapp: Bookmark, inViewController viewController: MyDappsViewController)
    func dismissKeyboard(inViewController viewController: MyDappsViewController)
    func didReorderDapps(inViewController viewController: MyDappsViewController)
}

class MyDappsViewController: UIViewController {
    @IBOutlet weak var logoImgView: UIImageView!
    @IBOutlet weak var bookmarkLbl: UILabel!
    @IBOutlet weak var tableView: UITableView!
    //    private let tableView = UITableView(frame: .zero, style: .plain)
    private var viewModel: MyDappsViewControllerViewModel
    private var browserNavBar: DappBrowserNavigationBar? {
        return navigationController?.navigationBar as? DappBrowserNavigationBar
    }
    private let bookmarksStore: BookmarksStore

    weak var delegate: MyDappsViewControllerDelegate?

    init(bookmarksStore: BookmarksStore) {
        self.bookmarksStore = bookmarksStore
        self.viewModel = .init(bookmarksStore: bookmarksStore)
        super.init(nibName: nil, bundle: nil)
        
        configure(viewModel: viewModel)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        print("MyDappsViewController")
        
        self.bookmarkLbl.text = viewModel.bookmarkLbl
        
        self.setupTableView()
        self.setupRefreshControl()
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    private func setupTableView() {
        self.tableView.register(MyDappCell.self)
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.separatorStyle = .none
        self.tableView.allowsSelectionDuringEditing = true
    }
    
    private func setupRefreshControl() {
        self.tableView.refreshControl = UIRefreshControl()
        self.tableView.refreshControl?.backgroundColor = UIColor.clear
        self.tableView.refreshControl?.tintColor = UIColor.clear
        self.tableView.refreshControl?.addTarget(self, action: #selector(pullToRefresh(_:)), for: .valueChanged)
        self.tableView.refreshControl?.addRefreshView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func pullToRefresh(_ refreshControl: UIRefreshControl) {
        if refreshControl.isRefreshing {
            refreshControl.showRefreshIndicator()
            self.delegate?.doRefresh(inViewController: self)
        }
    }

    @objc private func keyboardWillShow(notification: NSNotification) {
        if let keyboardEndFrame = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue, let _ = (notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            self.tableView.contentInset.bottom = keyboardEndFrame.size.height
        }
    }

    @objc private func keyboardWillHide(notification: NSNotification) {
        if let _ = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue, let _ = (notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            self.tableView.contentInset.bottom = 0
        }
    }
    
    func reloadTable() {
        self.tableView.reloadData()
        
        if self.tableView.refreshControl?.isRefreshing ?? false {
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                self.tableView.refreshControl?.endRefreshing()
                self.tableView.refreshControl?.hideRefreshIndicator()
            }
        }
    }

    func configure(viewModel: MyDappsViewControllerViewModel) {
        self.viewModel = viewModel
    }

    private func dismissKeyboard() {
        self.delegate?.dismissKeyboard(inViewController: self)
    }
}

extension MyDappsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return .zero
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: MyDappCell = tableView.dequeueReusableCell(for: indexPath)
        let dapp = viewModel.dapp(atIndex: indexPath.row)
        cell.selectionStyle = .none
        cell.configure(viewModel: .init(dapp: dapp))
        return cell
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.dappsCount
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if viewModel.dappsCount > 0 {
            tableView.backgroundView = nil
            
            return 1
        } else {
            let nib = UINib(nibName: "DappNoData", bundle: nil)
            let myNibView = nib.instantiate(withOwner: self, options: nil)[0] as? DappNoData
            tableView.backgroundView  = myNibView
            tableView.separatorStyle  = .none
            tableView.tableFooterView = nil
            
            return 0
        }
    }
}

extension MyDappsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let dapp = viewModel.dapp(atIndex: indexPath.row)
        dismissKeyboard()
        self.delegate?.didTapToSelect(dapp: dapp, inViewController: self)
//        if tableView.isEditing {
//            delegate?.didTapToEdit(dapp: dapp, inViewController: self)
//        } else {
//            dismissKeyboard()
//            delegate?.didTapToSelect(dapp: dapp, inViewController: self)
//        }
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let dapp = viewModel.dapp(atIndex: indexPath.row)
            confirm(
                    title: R.string.localizable.dappBrowserClearMyDapps(),
                    message: dapp.title,
                    okTitle: R.string.localizable.removeButtonTitle(),
                    okStyle: .destructive
            ) { [weak self] result in
                switch result {
                case .success:
                    guard let strongSelf = self else { return }
                    strongSelf.delegate?.delete(dapp: dapp, inViewController: strongSelf)
                case .failure:
                    break
                }
            }
        }
    }
}
