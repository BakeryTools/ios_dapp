// Copyright © 2020 Stormbird PTE. LTD.

import UIKit
import BigInt
import StatefulViewController

protocol ActivitiesViewControllerDelegate: AnyObject {
    func didPressActivity(activity: Activity, in viewController: ActivitiesViewController)
    func didPressTransaction(transaction: TransactionInstance, in viewController: ActivitiesViewController)
}

protocol ActivitiesViewDelegate: AnyObject {
    func didPressActivity(activity: Activity, in view: ActivitiesView)
    func didPressTransaction(transaction: TransactionInstance, in view: ActivitiesView)
}

class ActivitiesView: UIView {
    private var viewModel: ActivitiesViewModel
    private let sessions: ServerDictionary<WalletSession>
    private let tableView = UITableView(frame: .zero, style: .grouped)

    weak var delegate: ActivitiesViewDelegate?

    init(viewModel: ActivitiesViewModel, sessions: ServerDictionary<WalletSession>) {
        self.viewModel = viewModel
        self.sessions = sessions

        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false

        tableView.register(ActivityViewCell.self)
        tableView.register(DefaultActivityItemViewCell.self)
        tableView.register(TransactionViewCell.self)
        tableView.register(GroupActivityViewCell.self)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .singleLine
        tableView.backgroundColor = Colors.appBackground
        tableView.estimatedRowHeight = TokensCardViewController.anArbitraryRowHeightSoAutoSizingCellsWorkIniOS10

        addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: topAnchor),
            tableView.leadingAnchor.constraint(equalTo: leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])

        emptyView = TransactionsEmptyView(title: R.string.localizable.activityEmpty(), image: R.image.logo_login_page())
    }

    func resetStatefulStateToReleaseObjectToAvoidMemoryLeak() {
        // NOTE: Stateful lib set to object state machine that later causes ref cycle when applying it to view
        // here we release all associated objects to release state machine
        // this method callget get called while parent's view deinit get called
        objc_removeAssociatedObjects(self)
    }

    required init?(coder: NSCoder) {
        return nil
    }

    func reloadData() {
        tableView.reloadData()
    }

    func configure(viewModel: ActivitiesViewModel) {
        self.viewModel = viewModel
    }

    func applySearch(keyword: String?) {
        viewModel.filter(.keyword(keyword))

        reloadData()
    }
}

extension ActivitiesView: StatefulViewController {
    func hasContent() -> Bool {
        return viewModel.numberOfSections > 0
    }
}

extension ActivitiesView: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true )
        let item = viewModel.item(for: indexPath.row, section: indexPath.section)
        switch item {
        case .parentTransaction:
            break
        case .childActivity(_, activity: let activity):
            delegate?.didPressActivity(activity: activity, in: self)
        case .childTransaction(let transaction, _, let activity):
            if let activity = activity {
                delegate?.didPressActivity(activity: activity, in: self)
            } else {
                delegate?.didPressTransaction(transaction: transaction, in: self)
            }
        case .standaloneTransaction(transaction: let transaction, let activity):
            if let activity = activity {
                delegate?.didPressActivity(activity: activity, in: self)
            } else {
                delegate?.didPressTransaction(transaction: transaction, in: self)
            }
        case .standaloneActivity(activity: let activity):
            delegate?.didPressActivity(activity: activity, in: self)
        }
    }

    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        let item = viewModel.item(for: indexPath.row, section: indexPath.section)
        switch item {
        case .parentTransaction:
            return nil
        case .childActivity, .childTransaction, .standaloneTransaction, .standaloneActivity:
            return indexPath
        }
    }

    //Hide the footer
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        .leastNormalMagnitude
    }
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        nil
    }
}

extension ActivitiesView: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.numberOfSections
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = viewModel.item(for: indexPath.row, section: indexPath.section)
        switch item {
        case .parentTransaction(_, isSwap: let isSwap, _):
            let cell: GroupActivityViewCell = tableView.dequeueReusableCell(for: indexPath)
            cell.configure(viewModel: .init(groupType: isSwap ? .swap : .unknown))
            return cell
        case .childActivity(_, activity: let activity):
            let activity: Activity = {
                var a = activity
                a.rowType = .item
                return a
            }()
            switch activity.nativeViewType {
            case .erc20Received, .erc20Sent, .erc20OwnerApproved, .erc20ApprovalObtained, .erc721Received, .erc721Sent, .erc721OwnerApproved, .erc721ApprovalObtained, .nativeCryptoSent, .nativeCryptoReceived:
                let cell: DefaultActivityItemViewCell = tableView.dequeueReusableCell(for: indexPath)
                cell.configure(viewModel: .init(activity: activity))
                return cell
            case .none:
                let cell: ActivityViewCell = tableView.dequeueReusableCell(for: indexPath)
                cell.configure(viewModel: .init(activity: activity))
                return cell
            }
        case .childTransaction(transaction: let transaction, operation: let operation, let activity):
            if let activity = activity {
                let cell: DefaultActivityItemViewCell = tableView.dequeueReusableCell(for: indexPath)
                cell.configure(viewModel: .init(activity: activity))
                return cell
            } else {
                let cell: TransactionViewCell = tableView.dequeueReusableCell(for: indexPath)
                let session = sessions[transaction.server]
                cell.configure(viewModel: .init(transactionRow: .item(transaction: transaction, operation: operation), chainState: session.chainState, currentWallet: session.account, server: transaction.server))
                return cell
            }
        case .standaloneTransaction(transaction: let transaction, let activity):
            if let activity = activity {
                let cell: DefaultActivityItemViewCell = tableView.dequeueReusableCell(for: indexPath)
                cell.configure(viewModel: .init(activity: activity))
                return cell
            } else {
                let cell: TransactionViewCell = tableView.dequeueReusableCell(for: indexPath)
                let session = sessions[transaction.server]
                cell.configure(viewModel: .init(transactionRow: .standalone(transaction), chainState: session.chainState, currentWallet: session.account, server: transaction.server))
                return cell
            }
        case .standaloneActivity(activity: let activity):
            switch activity.nativeViewType {
            case .erc20Received, .erc20Sent, .erc20OwnerApproved, .erc20ApprovalObtained, .erc721Received, .erc721Sent, .erc721OwnerApproved, .erc721ApprovalObtained, .nativeCryptoSent, .nativeCryptoReceived:
                let cell: DefaultActivityItemViewCell = tableView.dequeueReusableCell(for: indexPath)
                cell.configure(viewModel: .init(activity: activity))
                return cell
            case .none:
                let cell: ActivityViewCell = tableView.dequeueReusableCell(for: indexPath)
                cell.configure(viewModel: .init(activity: activity))
                return cell
            }
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfItems(for: section)
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return ActivitiesViewController.functional.headerView(for: section, viewModel: viewModel)
    }

    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
    }

    fileprivate func headerView(for section: Int) -> UIView {
        let container = UIView()
        container.backgroundColor = Colors.appBackground
        let title = UILabel()
        title.text = viewModel.titleForHeader(in: section)
        title.sizeToFit()
        title.textColor = viewModel.headerTitleTextColor
        title.font = viewModel.headerTitleFont
        container.addSubview(title)
        title.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            title.anchorsConstraint(to: container, edgeInsets: .init(top: 18, left: 20, bottom: 16, right: 0))
        ])
        return container
    }
}

class ActivitiesViewController: UIViewController {
    private var viewModel: ActivitiesViewModel
    private let searchController: UISearchController
    private var isSearchBarConfigured = false
    private var bottomConstraint: NSLayoutConstraint!
    private lazy var keyboardChecker = KeyboardChecker(self, resetHeightDefaultValue: 0, ignoreBottomSafeArea: true)
    private var activitiesView: ActivitiesView
    weak var delegate: ActivitiesViewControllerDelegate?

    init(viewModel: ActivitiesViewModel, sessions: ServerDictionary<WalletSession>) {
        self.viewModel = viewModel
        searchController = UISearchController(searchResultsController: nil)
        activitiesView = ActivitiesView(viewModel: viewModel, sessions: sessions)
        super.init(nibName: nil, bundle: nil)

        title = R.string.localizable.activityTabbarItemTitle()
        activitiesView.delegate = self
        view.backgroundColor = Colors.appBackground

        bottomConstraint = activitiesView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        keyboardChecker.constraint = bottomConstraint

        view.addSubview(activitiesView)

        NSLayoutConstraint.activate([
            activitiesView.topAnchor.constraint(equalTo: view.topAnchor),
            activitiesView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            activitiesView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomConstraint,
        ])

        setupFilteringWithKeyword()
        configure(viewModel: viewModel)
    }

    deinit {
        activitiesView.resetStatefulStateToReleaseObjectToAvoidMemoryLeak()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        keyboardChecker.viewWillAppear()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        //NOTE: we call it here to show empty view if needed, as the reason that we don't have manually called callback where we can handle that loaded activities
        //next time view will be updated when configure with viewModel method get called.
        activitiesView.endLoading()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        keyboardChecker.viewWillDisappear()
    }

    func configure(viewModel: ActivitiesViewModel) {
        self.viewModel = viewModel

        activitiesView.configure(viewModel: viewModel)
        activitiesView.applySearch(keyword: searchController.searchBar.text)

        activitiesView.endLoading()
    }

    required init?(coder aDecoder: NSCoder) {
        return nil
    }

    override func viewDidLayoutSubviews() {
        configureSearchBarOnce()
    }
}

extension ActivitiesViewController: ActivitiesViewDelegate {
    func didPressActivity(activity: Activity, in view: ActivitiesView) {
        delegate?.didPressActivity(activity: activity, in: self)
    }

    func didPressTransaction(transaction: TransactionInstance, in view: ActivitiesView) {
        delegate?.didPressTransaction(transaction: transaction, in: self)
    }
}

extension ActivitiesViewController: UISearchResultsUpdating {
    //At least on iOS 13 beta on a device. updateSearchResults(for:) is called when we set `searchController.isActive = false` to dismiss search (because user tapped on a filter), but the value of `searchController.isActive` remains `false` during the call, hence the async.
    //This behavior is not observed in iOS 12, simulator
    public func updateSearchResults(for searchController: UISearchController) {
        processSearchWithKeywords()
    }

    private func processSearchWithKeywords() {
        activitiesView.applySearch(keyword: searchController.searchBar.text)
    }

}

extension ActivitiesViewController {

    private func makeSwitchToAnotherTabWorkWhileFiltering() {
        definesPresentationContext = true
    }

    private func doNotDimTableViewToReuseTableForFilteringResult() {
        searchController.dimsBackgroundDuringPresentation = false
    }

    private func wireUpSearchController() {
        searchController.searchResultsUpdater = self
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = true
    }

    private func fixNavigationBarAndStatusBarBackgroundColorForiOS13Dot1() {
        view.superview?.backgroundColor = Colors.appBackground
    }

    private func setupFilteringWithKeyword() {
        wireUpSearchController()
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

extension ActivitiesViewController {
    class functional {}
}

extension ActivitiesViewController.functional {

    fileprivate static func headerView(for section: Int, viewModel: ActivitiesViewModel) -> UIView {
        let container = UIView()
        container.backgroundColor = Colors.appBackground
        let title = UILabel()
        title.text = viewModel.titleForHeader(in: section)
        title.sizeToFit()
        title.textColor = viewModel.headerTitleTextColor
        title.font = viewModel.headerTitleFont
        container.addSubview(title)
        title.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            title.anchorsConstraint(to: container, edgeInsets: .init(top: 18, left: 20, bottom: 16, right: 0))
        ])
        return container
    }
}
