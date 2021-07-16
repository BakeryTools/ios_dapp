// Copyright © 2018 Stormbird PTE. LTD.

import UIKit
import Result
import StatefulViewController
import PromiseKit

protocol TokensViewControllerDelegate: class {
    func didPressAddToken( in viewController: UIViewController)
    func didPressAddHideTokens(viewModel: TokensViewModel)
    func didSelect(token: TokenObject, in viewController: UIViewController)
    func didHide(token: TokenObject, in viewController: UIViewController)
    func didTapOpenConsole(in viewController: UIViewController)
    func scanQRCodeSelected(in viewController: UIViewController)
    func blockieSelected(in viewController: UIViewController)
    func walletConnectSelected(in viewController: UIViewController)
}

class TokensViewController: UIViewController {
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
    private let backgroundImage = UIImageView()
    private var sections: [Section] = [.filters, .tokens]

    private var viewModel: TokensViewModel {
        didSet {
            viewModel.filter = oldValue.filter
            refreshView(viewModel: viewModel)
        }
    }
    private let sessions: ServerDictionary<WalletSession>
    private let account: Wallet
//    lazy private var tableViewFilterView = SegmentedControl(titles: TokensViewModel.segmentedControlTitles)
    lazy private var collectiblesCollectionViewFilterView = SegmentedControl(titles: TokensViewModel.segmentedControlTitles)
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.register(FungibleTokenViewCell.self)
        tableView.register(EthTokenViewCell.self)
        tableView.register(NonFungibleTokenViewCell.self)
        tableView.registerHeaderFooterView(TableViewSectionHeader.self)
//        tableView.registerHeaderFooterView(ShowAddHideTokensView.self)
        tableView.registerHeaderFooterView(ActiveWalletSessionView.self)
        tableView.estimatedRowHeight = DataEntry.Metric.TableView.estimatedRowHeight
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView.tableFooterToRemoveEmptyCellSeparators()
        tableView.separatorInset = .zero

        tableView.refreshControl = UIRefreshControl()
        tableView.refreshControl?.backgroundColor = UIColor.clear
        tableView.refreshControl?.tintColor = UIColor.clear
        tableView.refreshControl?.addTarget(self, action: #selector(pullToRefresh(_:)), for: .valueChanged)
        tableView.refreshControl?.addRefreshView()
        tableView.translatesAutoresizingMaskIntoConstraints = false

        return tableView
    }()
    private lazy var collectiblesCollectionViewRefreshControl: UIRefreshControl = {
        let control = UIRefreshControl()
        control.addTarget(self, action: #selector(pullToRefresh), for: .valueChanged)

        return control
    }()
    private lazy var collectiblesCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let numberOfColumns = CGFloat(3)
        let dimension = (UIScreen.main.bounds.size.width / numberOfColumns).rounded(.down)
        let heightForLabel = CGFloat(18)
        layout.itemSize = CGSize(width: dimension, height: dimension + heightForLabel)
        layout.minimumInteritemSpacing = 0
        layout.headerReferenceSize = .init(width: DataEntry.Metric.TableView.headerReferenceSizeWidth, height: TokensViewController.filterViewHeight)
        layout.sectionHeadersPinToVisibleBounds = true

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = viewModel.backgroundColor
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.alwaysBounceVertical = true
        collectionView.register(OpenSeaNonFungibleTokenViewCell.self)
        collectionView.registerSupplementaryView(CollectiblesCollectionViewHeader.self, of: UICollectionView.elementKindSectionHeader)
        collectionView.dataSource = self
        collectionView.isHidden = true
        collectionView.delegate = self
        collectionView.refreshControl = collectiblesCollectionViewRefreshControl

        return collectionView
    }()
//    private lazy var blockieImageView: BlockieImageView = {
//        let imageView = BlockieImageView()
//        imageView.translatesAutoresizingMaskIntoConstraints = false
//        imageView.clipsToBounds = true
//
//        NSLayoutConstraint.activate([
//            imageView.widthAnchor.constraint(equalToConstant: 24),
//            imageView.heightAnchor.constraint(equalToConstant: 24),
//        ])
//        return imageView
//    }()
    private var currentCollectiblesContractsDisplayed = [AlphaWallet.Address]()
    private let searchController: UISearchController
    private var isSearchBarConfigured = false
    private let hideTokenWidth: CGFloat = 170
    private var bottomConstraint: NSLayoutConstraint!
    private lazy var keyboardChecker = KeyboardChecker(self, resetHeightDefaultValue: 0, ignoreBottomSafeArea: true)
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
        searchController = UISearchController(searchResultsController: nil)

        super.init(nibName: nil, bundle: nil)
        handleTokenCollectionUpdates()
        
        self.backgroundImage.contentMode = .scaleAspectFill
        self.backgroundImage.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.backgroundImage)

//        tableViewFilterView.delegate = self
//        tableViewFilterView.translatesAutoresizingMaskIntoConstraints = false

        collectiblesCollectionViewFilterView.delegate = self
        collectiblesCollectionViewFilterView.translatesAutoresizingMaskIntoConstraints = false

        self.view.addSubview(tableView)
        self.view.addSubview(collectiblesCollectionView)

        bottomConstraint = tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        keyboardChecker.constraint = bottomConstraint

        NSLayoutConstraint.activate([
            self.backgroundImage.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            self.backgroundImage.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            self.backgroundImage.topAnchor.constraint(equalTo: view.topAnchor),
            self.backgroundImage.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomConstraint,
            collectiblesCollectionView.anchorsConstraint(to: tableView),
        ])

        errorView = ErrorView(onRetry: { [weak self] in
            self?.startLoading()
            self?.tokenCollection.fetch()
        })
        loadingView = LoadingView()
        emptyView = EmptyView(title: R.string.localizable.emptyViewNoTokensLabelTitle(), onRetry: { [weak self] in
            self?.startLoading()
            self?.tokenCollection.fetch()
        })

        refreshView(viewModel: viewModel)

        setupFilteringWithKeyword()
        let addTokenButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(self.addToken))
        addTokenButton.tintColor = Colors.tbakeDarkBrown
        self.navigationItem.rightBarButtonItem = addTokenButton
//        navigationItem.rightBarButtonItem = UIBarButtonItem.qrCodeBarButton(self, selector: #selector(scanQRCodeButtonSelected))
//        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: blockieImageView)

        walletConnectCoordinator.sessionsToURLServersMap.subscribe { [weak self] value in
            guard let strongSelf = self, let sessionsToURLServersMap = value else { return }
            if sessionsToURLServersMap.sessions.isEmpty {
                strongSelf.sections = [.filters, .tokens]
            } else {
                strongSelf.sections = [.filters, .activeWalletSession(count: sessionsToURLServersMap.sessions.count), .tokens]
            }
            strongSelf.tableView.reloadData()
        }
//        blockieImageView.button.addTarget(self, action: #selector(blockieButtonSelected), for: .touchUpInside)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.backgroundImage.image = UIImage(named: "background_img")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        print("TokensViewController")
        super.viewWillAppear(animated)

        navigationController?.applyTintAdjustment()
        self.navigationItem.largeTitleDisplayMode = .never
        hidesBottomBarWhenPushed = false

        fetch()
        fixNavigationBarAndStatusBarBackgroundColorForiOS13Dot1()
        keyboardChecker.viewWillAppear()
        getWalletName()
//        getWalletBlockie()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        keyboardChecker.viewWillDisappear()
    }
    
    override func viewDidLayoutSubviews() {
        //viewDidLayoutSubviews() is called many times
        configureSearchBarOnce()
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

//    private func getWalletBlockie() {
//        let generator = BlockiesGenerator()
//        generator.promise(address: account.address).done { [weak self] value in
//            self?.blockieImageView.image = value
//        }.catch { [weak self] _ in
//            self?.blockieImageView.image = nil
//        }
//    }

    func fetch() {
        tokenCollection.fetch()
    }

    private func reloadTableData() {
        tableView.reloadData()
    }

    private func reload() {
        collectiblesCollectionView.isHidden = !viewModel.shouldShowCollectiblesCollectionView
        reloadTableData()
        if viewModel.hasContent {
            if viewModel.shouldShowCollectiblesCollectionView {
                let contractsForCollectibles = contractsForCollectiblesFromViewModel()
                if contractsForCollectibles != currentCollectiblesContractsDisplayed {
                    currentCollectiblesContractsDisplayed = contractsForCollectibles
                    collectiblesCollectionView.reloadData()
                }
                tableView.dataSource = nil
            } else {
                tableView.dataSource = self
            }
        }
    }

    required init?(coder aDecoder: NSCoder) {
        return nil
    }

    func refreshView(viewModel: TokensViewModel) {
        view.backgroundColor = viewModel.backgroundColor
        tableView.backgroundColor = viewModel.backgroundColor
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
    private func contractsForCollectiblesFromViewModel() -> [AlphaWallet.Address] {
        var contractsForCollectibles = [AlphaWallet.Address]()
        for i in (0..<viewModel.numberOfItems()) {
            let token = viewModel.item(for: i, section: 0)
            contractsForCollectibles.append(token.contractAddress)
        }
        return contractsForCollectibles
    }

    private func handleTokenCollectionUpdates() {
        tokenCollection.subscribe { [weak self] result in
            guard let strongSelf = self else { return }
            switch result {
            case .success(let viewModel):
                strongSelf.viewModel = viewModel
                strongSelf.endLoading()
            case .failure(let error):
                strongSelf.endLoading(error: error)
            }
            strongSelf.reload()

            if strongSelf.tableView.refreshControl?.isRefreshing ?? false {
                DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                    strongSelf.tableView.refreshControl?.endRefreshing()
                    strongSelf.tableView.refreshControl?.hideRefreshIndicator()
                }
            }
            if strongSelf.collectiblesCollectionViewRefreshControl.isRefreshing {
                strongSelf.collectiblesCollectionViewRefreshControl.endRefreshing()
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
                    ticker: viewModel.ticker(for: token)
                ))
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
}

extension TokensViewController: SegmentedControlDelegate {
    func didTapSegment(atSelection selection: SegmentedControl.Selection, inSegmentedControl segmentedControl: SegmentedControl) {
        guard let filter = viewModel.convertSegmentedControlSelectionToFilter(selection) else { return }
        apply(filter: filter, withSegmentAtSelection: selection)
    }

    private func apply(filter: WalletFilter, withSegmentAtSelection selection: SegmentedControl.Selection?) {
        let previousFilter = viewModel.filter
        viewModel.filter = filter
        reload()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            //Important to update the segmented control (and hence add the segmented control back to the table) after they have been re-added to the table header through the table reload. Otherwise adding to the table header will break the animation for segmented control
            if let selection = selection {
                self.collectiblesCollectionViewFilterView.selection = selection
//                self.tableViewFilterView.selection = selection
            }
        }
        //Exit search if user tapped on the wallet filter. Careful to not trigger an infinite recursion between changing the filter by "category" and search keywords which are all based on filters
        if previousFilter == filter {
            //do nothing
        } else {
            switch filter {
            case .tokenOnly, .collectiblesOnly, .type:
                searchController.isActive = false
            case .keyword:
                break
            }
        }
    }
}

extension TokensViewController: UICollectionViewDataSource {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        //Defensive check to make sure we don't return the wrong count. iOS might decide to load (the first time especially) the collection view at some point even if we don't switch to it, thus getting the wrong count and then at some point asking for a cell for those non-existent rows/items. E.g 10 tokens total, only 3 are collectibles and asked for the 6th cell
        switch viewModel.filter {
        case .collectiblesOnly:
            return viewModel.numberOfItems()
        case .tokenOnly, .keyword, .type:
            return 0
        }
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let token = viewModel.item(for: indexPath.row, section: indexPath.section)
        let server = token.server
        let session = sessions[server]
        let cell: OpenSeaNonFungibleTokenViewCell = collectionView.dequeueReusableCell(for: indexPath)
        cell.configure(viewModel: .init(config: session.config, token: token, forWallet: account, assetDefinitionStore: assetDefinitionStore, eventsDataStore: eventsDataStore))
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let header: CollectiblesCollectionViewHeader = collectionView.dequeueReusableSupplementaryView(ofKind: kind, for: indexPath)
        header.filterView = collectiblesCollectionViewFilterView
        return header
    }
}

extension TokensViewController: UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectiblesCollectionView.deselectItem(at: indexPath, animated: true)
        let token = viewModel.item(for: indexPath.item, section: indexPath.section)
        delegate?.didSelect(token: token, in: self)
    }
}

extension TokensViewController: UISearchResultsUpdating {
    //At least on iOS 13 beta on a device. updateSearchResults(for:) is called when we set `searchController.isActive = false` to dismiss search (because user tapped on a filter), but the value of `searchController.isActive` remains `false` during the call, hence the async.
    //This behavior is not observed in iOS 12, simulator
    public func updateSearchResults(for searchController: UISearchController) {
        DispatchQueue.main.async {
            self.processSearchWithKeywords()
        }
    }

    private func processSearchWithKeywords() {
        guard searchController.isActive else {
            switch viewModel.filter {
            case .tokenOnly, .collectiblesOnly, .type:
                break
            case .keyword:
                //Handle when user taps Cancel button to stop search
                setDefaultFilter()
            }
            return
        }
        let keyword = searchController.searchBar.text ?? ""
        updateResults(withKeyword: keyword)
    }

    private func updateResults(withKeyword keyword: String) {
//        tableViewFilterView.selection = .unselected
        apply(filter: .keyword(keyword), withSegmentAtSelection: nil)
    }

    private func setDefaultFilter() {
        apply(filter: .tokenOnly, withSegmentAtSelection: .selected(0))
    }
}

///Support searching/filtering tokens with keywords. This extension is set up so it's easier to copy and paste this functionality elsewhere
extension TokensViewController {
    private func makeSwitchToAnotherTabWorkWhileFiltering() {
        definesPresentationContext = true
    }

    private func doNotDimTableViewToReuseTableForFilteringResult() {
        searchController.obscuresBackgroundDuringPresentation = false
    }

    private func wireUpSearchController() {
        searchController.searchResultsUpdater = self
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = true
    }

    private func fixTableViewBackgroundColor() {
        let v = UIView()
        v.backgroundColor = viewModel.backgroundColor
        tableView.backgroundView?.backgroundColor = viewModel.backgroundColor
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

extension TokensViewController: ShowAddHideTokensViewDelegate {
    func view(_ view: ShowAddHideTokensView, didSelectAddHideTokensButton sender: UIButton) {
//        delegate?.didPressAddHideTokens(viewModel: viewModel)
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
