// Copyright © 2020 Stormbird PTE. LTD.

import UIKit
import StatefulViewController
import PromiseKit

protocol AddHideTokensViewControllerDelegate: AnyObject {
    func didMark(token: TokenObject, in viewController: UIViewController, isHidden: Bool)
    func didChangeOrder(tokens: [TokenObject], in viewController: UIViewController)
    func didClose(viewController: AddHideTokensViewController)
}

class AddHideTokensViewController: UIViewController {
    private let assetDefinitionStore: AssetDefinitionStore
    private var viewModel: AddHideTokensViewModel
    private let searchController: UISearchController
    private var isSearchBarConfigured = false
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.register(WalletTokenViewCell.self)
        tableView.register(PopularTokenViewCell.self)
        tableView.registerHeaderFooterView(AddHideTokenSectionHeaderView.self)
        tableView.isEditing = true
        tableView.estimatedRowHeight = 100
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .singleLine
        tableView.separatorInset = .zero
        tableView.contentInset = .zero
        tableView.contentOffset = .zero
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: 0.01))
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()
    private let refreshControl = UIRefreshControl()
    private var prefersLargeTitles: Bool?
    private let notificationCenter = NotificationCenter.default
    weak var delegate: AddHideTokensViewControllerDelegate?
    private let backgroundImage = UIImageView()

    init(viewModel: AddHideTokensViewModel, assetDefinitionStore: AssetDefinitionStore) {
        self.assetDefinitionStore = assetDefinitionStore
        self.viewModel = viewModel
        searchController = UISearchController(searchResultsController: nil)
        
        super.init(nibName: nil, bundle: nil)
        
        self.backgroundImage.contentMode = .scaleAspectFill
        self.backgroundImage.translatesAutoresizingMaskIntoConstraints = false
        
        self.view.addSubview(self.backgroundImage)
        self.view.addSubview(self.tableView)
        
        NSLayoutConstraint.activate([
            self.backgroundImage.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            self.backgroundImage.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            self.backgroundImage.topAnchor.constraint(equalTo: view.topAnchor),
            self.backgroundImage.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            self.tableView.topAnchor.constraint(equalTo: view.topAnchor),
            self.tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            self.tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            self.tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        hidesBottomBarWhenPushed = true
    }

    required init?(coder: NSCoder) {
        return nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configure(viewModel: viewModel)
        setupFilteringWithKeyword()
        
        self.backgroundImage.image = UIImage(named: "background_img")
    }

    override func viewWillAppear(_ animated: Bool) {
        print("AddHideTokensViewController")
        super.viewWillAppear(animated)

        notificationCenter.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)

        prefersLargeTitles = navigationController?.navigationBar.prefersLargeTitles
        navigationController?.navigationBar.prefersLargeTitles = false

        reload()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        notificationCenter.removeObserver(self)

        if isMovingFromParent || isBeingDismissed {
            if let prefersLargeTitles = prefersLargeTitles {
                //This unfortunately breaks the smooth animation if we pop back and show the large title
                navigationController?.navigationBar.prefersLargeTitles = prefersLargeTitles
            }
            delegate?.didClose(viewController: self)
            return
        }
    }

    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let change = notification.keyboardInfo else {
            return
        }

        let bottom = change.endFrame.height - UIApplication.shared.bottomSafeAreaHeight

        UIView.animate(withDuration: change.duration, delay: 0, options: .curveEaseIn, animations: {
            self.tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: bottom, right: 0)
            self.tableView.scrollIndicatorInsets = self.tableView.contentInset
        }, completion: { _ in

        })
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        guard let change = notification.keyboardInfo else {
            return
        }

        UIView.animate(withDuration: change.duration, delay: 0, options: .curveEaseOut, animations: {
            self.tableView.contentInset = .zero
            self.tableView.scrollIndicatorInsets = self.tableView.contentInset
        }, completion: { _ in

        })
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        configureSearchBarOnce()
    }

    private func configure(viewModel: AddHideTokensViewModel) {
        title = viewModel.title
        self.tableView.backgroundColor = viewModel.backgroundColor
    }

    private func reload() {
        tableView.reloadData()
    }

    func add(token: TokenObject) {
        viewModel.add(token: token)
        reload()
    }

    func add(popularTokens: [PopularToken]) {
        viewModel.set(allPopularTokens: popularTokens)
        
        DispatchQueue.main.async {
            self.reload()
        }
    }
}

extension AddHideTokensViewController: StatefulViewController {
    //Always return true, otherwise users will be stuck in the assets sub-tab when they have no assets
    func hasContent() -> Bool {
        true
    }
}

extension AddHideTokensViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        viewModel.numberOfSections
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.numberOfItems(section)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let token = viewModel.item(atIndexPath: indexPath) else { return UITableViewCell() }
        let isVisible = viewModel.displayedToken(indexPath: indexPath)

        switch token {
        case .walletToken(let tokenObject):
            let cell: WalletTokenViewCell = tableView.dequeueReusableCell(for: indexPath)
            cell.configure(viewModel: .init(token: tokenObject, assetDefinitionStore: assetDefinitionStore, isVisible: isVisible))

            return cell
        case .popularToken(let value):
            let cell: PopularTokenViewCell = tableView.dequeueReusableCell(for: indexPath)
            cell.configure(viewModel: .init(token: value, isVisible: isVisible))

            return cell
        }
    }

    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        if let tokens = viewModel.moveItem(from: sourceIndexPath, to: destinationIndexPath) {
            delegate?.didChangeOrder(tokens: tokens, in: self)
        }
        tableView.reloadData()
    }

    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        viewModel.canMoveItem(indexPath: indexPath)
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        let promise: Promise<(token: TokenObject, indexPathToInsert: IndexPath, withTokenCreation: Bool)?>
        let isTokenHidden: Bool
        switch editingStyle {
        case .insert:
            promise = viewModel.addDisplayed(indexPath: indexPath)
            isTokenHidden = false
        case .delete:
            promise = viewModel.deleteToken(indexPath: indexPath)
            isTokenHidden = true
        case .none:
            promise = .value(nil)
            isTokenHidden = false
        }

        self.displayLoading()

        promise.done { [weak self] result in
            guard let strongSelf = self else { return }
            
            if let result = result, let delegate = strongSelf.delegate {
                delegate.didMark(token: result.token, in: strongSelf, isHidden: isTokenHidden)
                //NOTE: due to a table view BatchUpdates the table view can cracs we apply flag `withTokenCreation` to determine whether we create a new token, an if we do, reload table view
                tableView.reloadData()
//                if result.withTokenCreation {
//                    tableView.reloadData()
//                } else {
//                    tableView.performBatchUpdates({
//                        tableView.deleteRows(at: [indexPath], with: .automatic)
//                        tableView.insertRows(at: [result.indexPathToInsert], with: .automatic)
//                    }, completion: nil)
//                }
            } else {
                tableView.reloadData()
            }
        }.catch { _ in
            tableView.reloadData()

            self.displayError(message: R.string.localizable.walletsHideTokenErrorAddTokenFailure())
        }.finally {
            self.hideLoading()
        }
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let title = R.string.localizable.walletsHideTokenTitle()
        let hideAction = UIContextualAction(style: .destructive, title: title) { [weak self] _, _, completionHandler in
            guard let strongSelf = self else { return }

            strongSelf.viewModel.deleteToken(indexPath: indexPath).done { result in
                if let result = result, let delegate = strongSelf.delegate {
                    delegate.didMark(token: result.token, in: strongSelf, isHidden: true)

                    tableView.performBatchUpdates({
                        tableView.deleteRows(at: [indexPath], with: .automatic)
                        tableView.insertRows(at: [result.indexPathToInsert], with: .automatic)
                    }, completion: nil)

                    completionHandler(true)
                } else {
                    tableView.reloadData()

                    completionHandler(false)
                }
            }.cauterize()
        }

        hideAction.backgroundColor = R.color.danger()
        hideAction.image = R.image.hideToken()

        let configuration = UISwipeActionsConfiguration(actions: [hideAction])
        configuration.performsFirstActionWithFullSwipe = true

        return configuration
    }
}

extension AddHideTokensViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        viewModel.editingStyle(indexPath: indexPath)
    }

    func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        false
    }

    func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        if sourceIndexPath.section != proposedDestinationIndexPath.section {
            var row = 0
            if sourceIndexPath.section < proposedDestinationIndexPath.section {
                row = self.tableView(tableView, numberOfRowsInSection: sourceIndexPath.section) - 1
            }
            return IndexPath(row: row, section: sourceIndexPath.section)
        }
        return proposedDestinationIndexPath
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view: AddHideTokenSectionHeaderView = tableView.dequeueReusableHeaderFooterView()
        view.configure(viewModel: .init(text: viewModel.titleForSection(section)))

        return view
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        65
    }

    //Hide the footer
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        .leastNormalMagnitude
    }
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        nil
    }
}

extension AddHideTokensViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        DispatchQueue.main.async { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.viewModel.searchText = searchController.searchBar.text ?? ""
            strongSelf.reload()
        }
    }
}

///Support searching/filtering tokens with keywords. This extension is set up so it's easier to copy and paste this functionality elsewhere
extension AddHideTokensViewController {
    private func makeSwitchToAnotherTabWorkWhileFiltering() {
        definesPresentationContext = true
    }

    private func doNotDimTableViewToReuseTableForFilteringResult() {
        searchController.obscuresBackgroundDuringPresentation = false
    }

    private func wireUpSearchController() {
        searchController.searchResultsUpdater = self
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
    }

    private func fixTableViewBackgroundColor() {
        let v = UIView()
        v.backgroundColor = viewModel.backgroundColor
        tableView.backgroundView = v
    }

    private func fixNavigationBarAndStatusBarBackgroundColorForiOS13Dot1() {
        view.superview?.backgroundColor = viewModel.backgroundColor
    }

    private func setupFilteringWithKeyword() {
        wireUpSearchController()
        fixTableViewBackgroundColor()
        doNotDimTableViewToReuseTableForFilteringResult()
        makeSwitchToAnotherTabWorkWhileFiltering()
    }

    //Makes a difference where this is called from. Can't be too early
    private func configureSearchBarOnce() {
        guard !isSearchBarConfigured else { return }
        isSearchBarConfigured = true

        if let placeholderLabel = searchController.searchBar.firstSubview(ofType: UILabel.self) {
            placeholderLabel.textColor = Colors.lightGray
        }
        if let textField = searchController.searchBar.firstSubview(ofType: UITextField.self) {
            textField.textColor = Colors.appText
            if let imageView = textField.leftView as? UIImageView {
                imageView.image = imageView.image?.withRenderingMode(.alwaysTemplate)
                imageView.tintColor = Colors.appText
            }
        }
        //Hack to hide the horizontal separator below the search bar
        searchController.searchBar.superview?.firstSubview(ofType: UIImageView.self)?.isHidden = true
    }
}
