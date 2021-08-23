// Copyright © 2018 Stormbird PTE. LTD.

import UIKit
import Result
import StatefulViewController
import PromiseKit

protocol TokensViewControllerDelegate: AnyObject {
    func didPressAddToken( in viewController: UIViewController)
    func didPressAddHideTokens(viewModel: TokensViewModel)
    func didSelect(token: TokenObject, in viewController: UIViewController)
    func didHide(token: TokenObject, in viewController: UIViewController)
    func didTapOpenConsole(in viewController: UIViewController)
    func scanQRCodeSelected(in viewController: UIViewController)
    func blockieSelected(in viewController: UIViewController)
    func walletConnectSelected(in viewController: UIViewController)
    func goToHistory()
}

class TokensViewController: UIViewController {
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    
    private static let filterViewHeight = DataEntry.Metric.Tokens.Filter.height
    private static let addHideTokensViewHeight = DataEntry.Metric.AddHideToken.Header.height

    private enum Section {
        case filters
//        case addHideToken
        case tokens
        case activeWalletSession(count: Int)
    }

    private let tokenCollection: TokenCollection
    private let assetDefinitionStore: AssetDefinitionStore
    private let eventsDataStore: EventsDataStoreProtocol
    private var sections: [Section] = [.filters, .tokens]
    private var tokensPrice: [TokenDetails] = []

    private var viewModel: TokensViewModel {
        didSet {
            viewModel.filter = oldValue.filter
            refreshView(viewModel: viewModel)
        }
    }
    private let sessions: ServerDictionary<WalletSession>
    private let account: Wallet

    private let config: Config
    private let walletConnectCoordinator: WalletConnectCoordinator

    weak var delegate: TokensViewControllerDelegate?
    //TODO The name "bad" isn't correct. Because it includes "conflicts" too

    init(sessions: ServerDictionary<WalletSession>,
         account: Wallet,
         tokenCollection: TokenCollection,
         assetDefinitionStore: AssetDefinitionStore,
         eventsDataStore: EventsDataStoreProtocol,
         filterTokensCoordinator: FilterTokensCoordinator,
         config: Config,
         walletConnectCoordinator: WalletConnectCoordinator
    ) {
        self.sessions = sessions
        self.account = account
        self.tokenCollection = tokenCollection
        self.assetDefinitionStore = assetDefinitionStore
        self.eventsDataStore = eventsDataStore
        self.config = config
        self.walletConnectCoordinator = walletConnectCoordinator

        viewModel = TokensViewModel(filterTokensCoordinator: filterTokensCoordinator, tokens: [], tickers: .init())

        super.init(nibName: nil, bundle: nil)

        errorView = ErrorView(onRetry: { [weak self] in
            self?.startLoading()
            self?.tokenCollection.fetch()
        })
        loadingView = LoadingView()
        emptyView = EmptyView(title: R.string.localizable.emptyViewNoTokensLabelTitle(), onRetry: { [weak self] in
            guard let self = self else { return }
            self.startLoading()
            self.tokenCollection.fetch()
        })

        refreshView(viewModel: viewModel)

        walletConnectCoordinator.sessionsToURLServersMap.subscribe { [weak self] value in
            guard let strongSelf = self, let sessionsToURLServersMap = value else { return }
            if sessionsToURLServersMap.sessions.isEmpty {
                strongSelf.sections = [.filters, .tokens]
            } else {
                strongSelf.sections = [.filters, .activeWalletSession(count: sessionsToURLServersMap.sessions.count), .tokens]
            }
            strongSelf.tableView.reloadData()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupTableView()
        self.setupNavigationBar()
        self.setupSearchBar()
        
        self.handleTokenCollectionUpdates() {
            self.loadPrice() {
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        print("TokensViewController")
        super.viewWillAppear(animated)

        navigationController?.applyTintAdjustment()
        self.navigationItem.largeTitleDisplayMode = .never
        hidesBottomBarWhenPushed = false

        fetch()
        getWalletName()
    }
    
    private func getWalletName() {
        title = viewModel.walletDefaultTitle
        
        firstly {
            GetWalletNameCoordinator(config: config).getName(forAddress: account.address)
        }.done { [weak self] name in
            guard let strongSelf = self else { return }
            strongSelf.navigationItem.title = name ?? strongSelf.viewModel.walletDefaultTitle
        }.cauterize()
    }
    
    func setupSearchBar() {
        self.searchBar.searchTextField.backgroundColor = Colors.appBackground
        self.searchBar.searchTextField.font = Screen.TokenCard.Font.subtitle
        self.searchBar.searchTextField.textColor = Screen.TokenCard.Color.subtitle
        self.searchBar.searchTextField.placeholder = R.string.localizable.searchbarPlaceholder()
        self.searchBar.showsCancelButton = false
        self.searchBar.delegate = self
    }
    
    private func setupNavigationBar() {
        let addTokenButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(self.addToken))
        addTokenButton.tintColor = Colors.tbakeDarkBrown
        self.navigationItem.rightBarButtonItem = addTokenButton
        
        let activityButton = UIBarButtonItem(title: R.string.localizable.goToHistoryTitle(), style: .done, target: self, action: #selector(self.goToHistory))
        activityButton.tintColor = Colors.tbakeDarkBrown
        self.navigationItem.leftBarButtonItem = activityButton
    }

    private func setupTableView() {
        self.tableView.register(FungibleTokenViewCell.self)
        self.tableView.register(EthTokenViewCell.self)
        self.tableView.register(NonFungibleTokenViewCell.self)
        self.tableView.registerHeaderFooterView(ActiveWalletSessionView.self)
        self.tableView.estimatedRowHeight = DataEntry.Metric.TableView.estimatedRowHeight
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.tableFooterView = UIView.tableFooterToRemoveEmptyCellSeparators()
        self.tableView.separatorInset = .zero
        self.tableView.backgroundColor = Colors.backgroundClear
        self.tableView.refreshControl = UIRefreshControl()
        self.tableView.refreshControl?.backgroundColor = Colors.backgroundClear
        self.tableView.refreshControl?.tintColor = UIColor.clear
        self.tableView.refreshControl?.addTarget(self, action: #selector(pullToRefresh(_:)), for: .valueChanged)
        self.tableView.refreshControl?.addRefreshView()
    }

    func fetch() {
        tokenCollection.fetch()
    }

    private func reloadTableData() {
        tableView.reloadData()
    }

    private func reload() {
        reloadTableData()
        if viewModel.hasContent {
            tableView.dataSource = self
        }
    }

    required init?(coder aDecoder: NSCoder) {
        return nil
    }

    func refreshView(viewModel: TokensViewModel) {
        view.backgroundColor = viewModel.backgroundColor
    }
    
    private func makeMoreAlertSheet() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet )
        
        alertController.view.tintColor = Colors.tbakeDarkBrown
        
        let addNewToken = UIAlertAction(title: R.string.localizable.tokensNewtokenNavigationTitle(), style: .default) { [weak self] _ in
            guard let self = self else { return }
            self.delegate?.didPressAddToken(in: self)
        }

        let addHideToken = UIAlertAction(title: R.string.localizable.tokensHidetokenNavigationTitle(), style: .default) { [weak self] _ in
            guard let self = self else { return }
            self.delegate?.didPressAddHideTokens(viewModel: self.viewModel)
        }

        let cancelAction = UIAlertAction(title: R.string.localizable.cancel(), style: .cancel) { _ in }
        
        alertController.addAction(addNewToken)
        alertController.addAction(addHideToken)
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true, completion: nil)
    }

    //Reloading the collectibles tab is very obvious visually, with the flashing images even if there are no changes. So we used this to check if the list of collectibles have changed, if not, don't refresh. We could have used a library that tracks diff, but that is overkill and one more dependency
    private func contractsForCollectiblesFromViewModel() -> [TBakeWallet.Address] {
        var contractsForCollectibles = [TBakeWallet.Address]()
        for i in (0..<viewModel.numberOfItems()) {
            let token = viewModel.item(for: i, section: 0)
            contractsForCollectibles.append(token.contractAddress)
        }
        return contractsForCollectibles
    }

    private func handleTokenCollectionUpdates(completion: @escaping (() ->(Void))) {
        tokenCollection.subscribe { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let viewModel):
                self.viewModel = viewModel
                self.endLoading()
            case .failure(let error):
                self.endLoading(error: error)
            }
            
            self.reload()

            if self.tableView.refreshControl?.isRefreshing ?? false {
                DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                    self.tableView.refreshControl?.endRefreshing()
                    self.tableView.refreshControl?.hideRefreshIndicator()
                }
            }
            
            completion()
        }
    }
    
    private func loadPrice(completion: @escaping (() ->(Void))) {
        for token in viewModel.tokens {
            self.loadPriceFromPancakeswap(address: token.contract) { data in
                let price = TokenDetails(name: data?.name, symbol: data?.symbol, price: data?.price, price_BNB: data?.price_BNB)
                DispatchQueue.main.async { self.tokensPrice.append(price) }
            }
        }
        completion()
    }
    
    private func loadPriceFromPancakeswap(address: String, completion: @escaping ((_ data: TokenDetails?) -> ())) {
        let jsonUrlString = "https://api.pancakeswap.info/api/v2/tokens/\(address)"
        
        WebService().getData(jsonUrlString){ data in
            do {
                let dataJSON = try JSONDecoder().decode(PancakeSwapPrice.self, from: data)
                completion(dataJSON.data)
            }catch let error {
                print(error)
            }
        }
    }
    
    @objc private func blockieButtonSelected(_ sender: UIButton) {
        delegate?.blockieSelected(in: self)
    }
    
    @objc private func addToken() {
        self.makeMoreAlertSheet()
    }

    @objc func pullToRefresh(_ refreshControl: UIRefreshControl) {
        if refreshControl.isRefreshing {
            refreshControl.showRefreshIndicator()
            fetch()
        }
    }

    @objc func openConsole() {
        delegate?.didTapOpenConsole(in: self)
    }
    
    @objc func goToHistory() {
        delegate?.goToHistory()
    }
}

extension TokensViewController: StatefulViewController {
    //Always return true, otherwise users will be stuck in the assets sub-tab when they have no assets
    func hasContent() -> Bool {
        return true
    }
}

extension TokensViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let token = viewModel.item(for: indexPath.row, section: indexPath.section)
        delegate?.didSelect(token: token, in: self)
    }

    //Hide the footer
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        .leastNormalMagnitude
    }
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        nil
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch sections[section] {
        case .filters:
            return .zero //TokensViewController.filterViewHeight
        case .activeWalletSession:
            return 80
        case .tokens:
            return 0.01
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        switch sections[section] {
        case .filters:
            return nil
//            let header: TableViewSectionHeader = tableView.dequeueReusableHeaderFooterView()
//            header.filterView = tableViewFilterView
//
//            return header
        case .activeWalletSession(let count):
            let header: ActiveWalletSessionView = tableView.dequeueReusableHeaderFooterView()
            header.configure(viewModel: .init(count: count))
            header.delegate = self

            return header
        case .tokens:
            return nil
        }
    }
}

extension TokensViewController: ActiveWalletSessionViewDelegate {

    func view(_ view: ActiveWalletSessionView, didSelectTap sender: UITapGestureRecognizer) {
        delegate?.walletConnectSelected(in: self)
    }
}

extension TokensViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch sections[indexPath.section] {
        case .filters, .activeWalletSession:
            return UITableViewCell()
        case .tokens:
            let token = viewModel.item(for: indexPath.row, section: indexPath.section)
            let server = token.server
            let session = sessions[server]
            switch token.type {
            case .nativeCryptocurrency:
                let cell: EthTokenViewCell = tableView.dequeueReusableCell(for: indexPath)
                cell.configure(viewModel: .init(
                    token: token,
                    ticker: viewModel.ticker(for: token),
                    currencyAmount: session.balanceCoordinator.viewModel.currencyAmount,
                    assetDefinitionStore: assetDefinitionStore
                ))
                return cell
            case .erc20:
                let cell: FungibleTokenViewCell = tableView.dequeueReusableCell(for: indexPath)
                cell.configure(viewModel: .init(token: token,
                    assetDefinitionStore: assetDefinitionStore,
                    isVisible: isVisible,
                    ticker: viewModel.ticker(for: token)),
                    token: token,
                    price: self.tokensPrice
                )
                return cell
                
            case .erc721, .erc721ForTickets:
                let cell: NonFungibleTokenViewCell = tableView.dequeueReusableCell(for: indexPath)
                cell.configure(viewModel: .init(token: token, server: server, assetDefinitionStore: assetDefinitionStore))
                return cell
            case .erc875:
                let cell: NonFungibleTokenViewCell = tableView.dequeueReusableCell(for: indexPath)
                cell.configure(viewModel: .init(token: token, server: server, assetDefinitionStore: assetDefinitionStore))
                return cell
            }
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch sections[section] {
        case .filters, .activeWalletSession:
            return 0
        case .tokens:
            return viewModel.numberOfItems()
        }
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        sections.count
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        switch sections[indexPath.section] {
        case .filters, .activeWalletSession:
            return nil
        case .tokens:
            let token = viewModel.item(for: indexPath.row, section: indexPath.section)
            switch token.type {
            case .nativeCryptocurrency:
                return nil
            default:
                if token.contract == "0x26D6e280F9687c463420908740AE59f712419147" {
                    return nil
                } else {
                    return trailingSwipeActionsConfiguration(forRowAt: indexPath)
                }
            }
        }
    }

    private func trailingSwipeActionsConfiguration(forRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let title = R.string.localizable.walletsHideTokenTitle()
        let hideAction = UIContextualAction(style: .destructive, title: title) { [weak self] (_, _, completionHandler) in
            guard let strongSelf = self else { return }
            let token = strongSelf.viewModel.item(for: indexPath.row, section: indexPath.section)
            strongSelf.delegate?.didHide(token: token, in: strongSelf)

            let didHideToken = strongSelf.viewModel.markTokenHidden(token: token)
            if didHideToken {
                strongSelf.tableView.deleteRows(at: [indexPath], with: .automatic)
            } else {
                strongSelf.reloadTableData()
            }

            completionHandler(didHideToken)
        }

        hideAction.backgroundColor = R.color.danger()
        hideAction.image = R.image.hideToken()
        let configuration = UISwipeActionsConfiguration(actions: [hideAction])
        configuration.performsFirstActionWithFullSwipe = true

        return configuration
    }
    
    private func updateResults(withKeyword keyword: String) {
        apply(filter: .keyword(keyword), withSegmentAtSelection: nil)
    }
    
    private func setDefaultFilter() {
        apply(filter: .tokenOnly, withSegmentAtSelection: .selected(0))
    }
    
    private func apply(filter: WalletFilter, withSegmentAtSelection selection: SegmentedControl.Selection?) {
        let previousFilter = viewModel.filter
        viewModel.filter = filter
        reload()
    
        //Exit search if user tapped on the wallet filter. Careful to not trigger an infinite recursion between changing the filter by "category" and search keywords which are all based on filters
        if previousFilter == filter {
            //do nothing
        } else {
            switch filter {
            case .tokenOnly, .collectiblesOnly, .type:
                break
            case .keyword:
                break
            }
        }
    }
}

// MARK: - SearchBar Delegate
extension TokensViewController: UISearchBarDelegate {
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
       UIView.animate(withDuration: 0.3, delay: 0.15, options: .curveEaseIn, animations: {
            self.searchBar.showsCancelButton = true
       }, completion: { finished in
       })
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        let keyword = searchBar.text ?? ""
        updateResults(withKeyword: keyword)
    }
       
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        UIView.animate(withDuration: 0.3, delay: 0.15, options: .curveEaseOut, animations: {
            self.searchBar.showsCancelButton = false
        }, completion: { finished in
        })
    }
       
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        self.view.endEditing(true)
        if searchBar.text.isEmpty {
            self.setDefaultFilter()
        }
    }
       
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        self.view.endEditing(true)
    }
}

extension UIBarButtonItem {
    static func qrCodeBarButton(_ target: AnyObject, selector: Selector) -> UIBarButtonItem {
        return .init(image: R.image.qr_code_icon(), style: .plain, target: target, action: selector)
    }

    static func addBarButton(_ target: AnyObject, selector: Selector) -> UIBarButtonItem {
        return .init(image: R.image.add_hide_tokens(), style: .plain, target: target, action: selector)
    }
}
