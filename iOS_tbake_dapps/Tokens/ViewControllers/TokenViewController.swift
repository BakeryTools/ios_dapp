// Copyright © 2018 Stormbird PTE. LTD.

import Foundation
import UIKit
import BigInt
import PromiseKit
import RealmSwift

protocol TokenViewControllerDelegate: AnyObject, CanOpenURL {
    func didTapSwap(forTransactionType transactionType: TransactionType, service: SwapTokenURLProviderType, inViewController viewController: TokenViewController)
    func shouldOpen(url: URL, shouldSwitchServer: Bool, forTransactionType transactionType: TransactionType, inViewController viewController: TokenViewController)
    func didTapSend(forTransactionType transactionType: TransactionType, inViewController viewController: TokenViewController)
    func didTapReceive(forTransactionType transactionType: TransactionType, inViewController viewController: TokenViewController)
    func didTap(transaction: TransactionInstance, inViewController viewController: TokenViewController)
    func didTap(activity: Activity, inViewController viewController: TokenViewController)
    func didTap(action: TokenInstanceAction, transactionType: TransactionType, viewController: TokenViewController)
    func goToChart(url: String?)
}

class TokenViewController: UIViewController {
    @IBOutlet weak var parentView: UIView!
    
    @IBOutlet weak var sendBtn: UIButton!
    @IBOutlet weak var receiveBtn: UIButton!
    
    private var viewModel: TokenViewControllerViewModel
    private var tokenHolder: TokenHolder?
    private let tokenObject: TokenObject
    private let session: WalletSession
    private let tokensDataStore: TokensDataStore
    private let assetDefinitionStore: AssetDefinitionStore
    private let transactionType: TransactionType
    private let analyticsCoordinator: AnalyticsCoordinator
    private lazy var tokenScriptFileStatusHandler = XMLHandler(token: tokenObject, assetDefinitionStore: assetDefinitionStore)
    
    weak var delegate: TokenViewControllerDelegate?
    
    private lazy var tokenInfoPageView: TokenInfoPageView = {
        let view = TokenInfoPageView(server: session.server, token: tokenObject, transactionType: transactionType)
        view.delegate = self

        return view
    }()
    
    private lazy var activityPageView: ActivityPageView = {
        let viewModel: ActivityPageViewModel = .init(activitiesViewModel: .init())
        let view = ActivityPageView(viewModel: viewModel, sessions: sessions)
        view.delegate = self

        return view
    }()
    
    private lazy var alertsPageView = AlertsPageView()
    private let sessions: ServerDictionary<WalletSession>
    private let activitiesService: ActivitiesServiceType

    init(session: WalletSession, tokensDataStore: TokensDataStore, assetDefinition: AssetDefinitionStore, transactionType: TransactionType, analyticsCoordinator: AnalyticsCoordinator, token: TokenObject, viewModel: TokenViewControllerViewModel, activitiesService: ActivitiesServiceType, sessions: ServerDictionary<WalletSession>) {
        self.tokenObject = token
        self.viewModel = viewModel
        self.session = session
        self.sessions = sessions
        self.tokensDataStore = tokensDataStore
        self.assetDefinitionStore = assetDefinition
        self.transactionType = transactionType
        self.analyticsCoordinator = analyticsCoordinator
        self.activitiesService = activitiesService

        super.init(nibName: nil, bundle: nil)
        
        activitiesService.subscribableViewModel.subscribe { [weak self] viewModel in
            guard let self = self, let viewModel = viewModel else { return }
            self.activityPageView.configure(viewModel: .init(activitiesViewModel: viewModel))
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        print("TokenViewController")
        self.setupView()
        self.setupBtn()
        self.configureBalanceViewModel()
        self.configure(viewModel: viewModel)
        self.setupNavigationBar()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupView() {
        let containerView = TokenPagesContainerView(pages: [tokenInfoPageView, activityPageView])
        self.parentView.addSubview(containerView)
        
        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(equalTo: parentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: parentView.trailingAnchor),
            containerView.topAnchor.constraint(equalTo: parentView.topAnchor),
            containerView.bottomAnchor.constraint(equalTo: parentView.bottomAnchor),
        ])
    }

    func setupNavigationBar() {
        if self.tokenObject.type != .nativeCryptocurrency {
            let addTokenButton = UIBarButtonItem(title: R.string.localizable.chartTabbarItemTitle(), style: .done, target: self, action: #selector(self.goToChart))
            addTokenButton.tintColor = Colors.tbakeDarkBrown
            self.navigationItem.rightBarButtonItem = addTokenButton
        }
    }
    
    func setupBtn() {
        self.sendBtn.layer.cornerRadius = 8.0
        self.receiveBtn.layer.cornerRadius = 8.0
        self.receiveBtn.layer.borderWidth = 1.0
        self.receiveBtn.layer.borderColor = Colors.tbakeDarkBrown.cgColor
        
        self.sendBtn.addTarget(self, action: #selector(self.doSend), for: .touchUpInside)
        self.receiveBtn.addTarget(self, action: #selector(self.doReceive), for: .touchUpInside)
        
        self.sendBtn.setTitle(self.viewModel.sendButtonTitle, for: .normal)
        self.receiveBtn.setTitle(self.viewModel.receiveButtonTitle, for: .normal)
    }
    
    func configure(viewModel: TokenViewControllerViewModel) {
        self.viewModel = viewModel
        
        var viewModel2 = tokenInfoPageView.viewModel
        viewModel2.values = viewModel.chartHistory

        tokenInfoPageView.configure(viewModel: viewModel2)

    }

    private func configureBalanceViewModel() {
        switch transactionType {
        case .nativeCryptocurrency:
            session.balanceViewModel.subscribe { [weak self] viewModel in
                guard let self = self, let viewModel = viewModel else { return }

                self.tokenInfoPageView.viewModel.title = "\(viewModel.amountShort) \(viewModel.symbol)"
                let etherToken = TokensDataStore.etherToken(forServer: self.session.server)
                self.tokenInfoPageView.viewModel.ticker = self.tokensDataStore.coinTicker(for: etherToken)
                self.tokenInfoPageView.viewModel.currencyAmount = self.session.balanceCoordinator.viewModel.currencyAmount

                self.configure(viewModel: self.viewModel)
            }

            session.refresh(.ethBalance)
        case .ERC20Token(let token, _, _):
            let amount = EtherNumberFormatter.short.string(from: token.valueBigInt, decimals: token.decimals)
            //Note that if we want to display the token name directly from token.name, we have to be careful that DAI token's name has trailing \0
            tokenInfoPageView.viewModel.title = "\(amount) \(token.symbolInPluralForm(withAssetDefinitionStore: assetDefinitionStore))"

            let etherToken = TokensDataStore.etherToken(forServer: session.server)

            tokenInfoPageView.viewModel.ticker = tokensDataStore.coinTicker(for: etherToken)
            tokenInfoPageView.viewModel.currencyAmount = session.balanceCoordinator.viewModel.currencyAmount

            configure(viewModel: viewModel)
        case .ERC875Token, .ERC875TokenOrder, .ERC721Token, .ERC721ForTicketToken, .dapp, .tokenScript, .claimPaidErc875MagicLink:
            break
        }

        self.title = self.tokenObject.symbol
    }
    
    @objc func goToChart() {
        let urlString = "https://chart.bakerytools.io/token/\(self.tokenObject.contract)"
        self.delegate?.goToChart(url: urlString)
    }

    @objc private func showContractWebPage() {
        self.delegate?.didPressViewContractWebPage(forContract: transactionType.contract, server: session.server, in: self)
    }
    
    @objc private func doSend(_ sender: UIButton) {
        self.delegate?.didTapSend(forTransactionType: transactionType, inViewController: self)
    }

    @objc private func doReceive(_ sender: UIButton) {
        self.delegate?.didTapReceive(forTransactionType: transactionType, inViewController: self)
    }

    private func generateTokenHolder() -> TokenHolder? {
        //TODO is it correct to generate the TokenHolder instance once and never replace it? If not, we have to be very careful with subscriptions. Not re-subscribing in an infinite loop
        guard tokenHolder == nil else { return tokenHolder }

        //TODO id 1 for fungibles. Might come back to bite us?
        let hardcodedTokenIdForFungibles = BigUInt(1)
        guard let tokenObject = viewModel.token else { return nil }
        let xmlHandler = XMLHandler(token: tokenObject, assetDefinitionStore: assetDefinitionStore)
        //TODO Event support, if/when designed for fungibles
        let values = xmlHandler.resolveAttributesBypassingCache(withTokenIdOrEvent: .tokenId(tokenId: hardcodedTokenIdForFungibles), server: self.session.server, account: self.session.account)
        let subscribablesForAttributeValues = values.values
        let allResolved = subscribablesForAttributeValues.allSatisfy { $0.subscribableValue?.value != nil }
        if allResolved {
            //no-op
        } else {
            for each in subscribablesForAttributeValues {
                guard let subscribable = each.subscribableValue else { continue }
                subscribable.subscribe { [weak self] _ in
                    guard let self = self else { return }
                    self.configure(viewModel: self.viewModel)
                }
            }
        }

        let token = Token(tokenIdOrEvent: .tokenId(tokenId: hardcodedTokenIdForFungibles), tokenType: tokenObject.type, index: 0, name: tokenObject.name, symbol: tokenObject.symbol, status: .available, values: values)
        tokenHolder = TokenHolder(tokens: [token], contractAddress: tokenObject.contractAddress, hasAssetDefinition: true)
        return tokenHolder
    }
}

extension TokenViewController: CanOpenURL2 {
    func open(url: URL) {
        delegate?.didPressOpenWebPage(url, in: self)
    }
}

extension TokenViewController: TokenInfoPageViewDelegate {
    func didPressViewContractWebPage(forContract contract: TBakeWallet.Address, in tokenInfoPageView: TokenInfoPageView) {
        delegate?.didPressViewContractWebPage(forContract: contract, server: session.server, in: self)
    }
}

extension TokenViewController: ActivityPageViewDelegate {
    func didTap(activity: Activity, in view: ActivityPageView) {
        delegate?.didTap(activity: activity, inViewController: self)
    }

    func didTap(transaction: TransactionInstance, in view: ActivityPageView) {
        delegate?.didTap(transaction: transaction, inViewController: self)
    }
}

// MARK: Analytics
extension TokenViewController {
    private func logStartOnRamp(name: String) {
        analyticsCoordinator.log(navigation: Analytics.Navigation.onRamp, properties: [Analytics.Properties.name.rawValue: name])
    }
}
