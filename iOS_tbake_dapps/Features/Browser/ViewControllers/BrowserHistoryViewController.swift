//
// Created by James Sangalli on 8/12/18.
//

import Foundation
import UIKit
import StatefulViewController

protocol BrowserHistoryViewControllerDelegate: AnyObject {
    func doRefresh(inViewController viewController: BrowserHistoryViewController)
    func didSelect(history: History, inViewController controller: BrowserHistoryViewController)
    func clearHistory(inViewController viewController: BrowserHistoryViewController)
    func dismissKeyboard(inViewController viewController: BrowserHistoryViewController)
}

final class BrowserHistoryViewController: UIViewController {
    @IBOutlet weak var logoImgView: UIImageView!
    @IBOutlet weak var historyLbl: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    private let store: HistoryStore
    private var viewModel: HistoriesViewModel

    weak var delegate: BrowserHistoryViewControllerDelegate?

    init(store: HistoryStore) {
        self.store = store
        self.viewModel = HistoriesViewModel(store: store)

        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("BrowserHistoryViewController")
        
        self.historyLbl.text = viewModel.historyTitle
        
        self.setupTableView()
        self.setupRefreshControl()
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    private func setupTableView() {
        self.tableView.register(BrowserHistoryCell.self)
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

    func fetch() {
        tableView.reloadData()
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

    func configure(viewModel: HistoriesViewModel) {
        self.viewModel = viewModel
    }
    
    func getHistoryData() -> Int {
        return viewModel.numberOfRows
    }
    
    func clearHistory() {
        UIAlertController.alert(
                title: R.string.localizable.dappBrowserClearHistory(),
                message: R.string.localizable.dappBrowserClearHistoryPrompt(),
                alertButtonTitles: [R.string.localizable.clearButtonTitle(), R.string.localizable.cancel()],
                alertButtonStyles: [.destructive, .cancel],
                viewController: self,
                completion: { [weak self] buttonIndex in
                    guard let strongSelf = self else { return }
                    if buttonIndex == 0 {
                        strongSelf.delegate?.clearHistory(inViewController: strongSelf)
                    }
        })
    }
    
    private func dismissKeyboard() {
        self.delegate?.dismissKeyboard(inViewController: self)
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
}

extension BrowserHistoryViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return .zero
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfRows
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: BrowserHistoryCell = tableView.dequeueReusableCell(for: indexPath)
        cell.selectionStyle = .none
        cell.configure(viewModel: .init(history: viewModel.item(for: indexPath)))
        return cell
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if viewModel.numberOfRows > 0 {
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

extension BrowserHistoryViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        delegate?.dismissKeyboard(inViewController: self)
        let history = viewModel.item(for: indexPath)
        delegate?.didSelect(history: history, inViewController: self)
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let history = viewModel.item(for: indexPath)
            confirm(
                    title: R.string.localizable.browserHistoryConfirmDeleteTitle(),
                    message: history.url,
                    okTitle: R.string.localizable.removeButtonTitle(),
                    okStyle: .destructive
            ) { [weak self] result in
                switch result {
                case .success:
                    guard let strongSelf = self else { return }
                    strongSelf.store.delete(histories: [history])
                    //TODO improve animation
                    strongSelf.tableView.reloadData()
                case .failure:
                    break
                }
            }
        }
    }
}
