// Copyright © 2018 Stormbird PTE. LTD.

import Foundation
import UIKit
import BigInt
import PromiseKit

protocol TokenViewControllerDelegate: AnyObject, CanOpenURL {
    func didTapSwap(forTransactionType transactionType: TransactionType, service: SwapTokenURLProviderType, inViewController viewController: TokenViewController)
    func shouldOpen(url: URL, shouldSwitchServer: Bool, forTransactionType transactionType: TransactionType, inViewController viewController: TokenViewController)
    func didTapSend(forTransactionType transactionType: TransactionType, inViewController viewController: TokenViewController)
    func didTapReceive(forTransactionType transactionType: TransactionType, inViewController viewController: TokenViewController)
    func didTap(transaction: TransactionInstance, inViewController viewController: TokenViewController)
    func didTap(action: TokenInstanceAction, transactionType: TransactionType, viewController: TokenViewController)
}

class TokenViewController: UIViewController {
    @IBOutlet weak var tokenImgView: UIImageView!
    @IBOutlet weak var tokenNameAndAmountLbl: UILabel!
    @IBOutlet weak var recentTransactionLbl: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var sendBtn: UIButton!
    @IBOutlet weak var receiveBtn: UIButton!
    
    lazy private var headerViewModel = SendHeaderViewViewModel(server: session.server, token: token, transactionType: transactionType)
    private var viewModel: TokenViewControllerViewModel?
    private var tokenHolder: TokenHolder?
    private let token: TokenObject
    private let session: WalletSession
    private let tokensDataStore: TokensDataStore
    private let assetDefinitionStore: AssetDefinitionStore
    private let transactionType: TransactionType
    private let analyticsCoordinator: AnalyticsCoordinator
    private lazy var tokenScriptFileStatusHandler = XMLHandler(token: token, assetDefinitionStore: assetDefinitionStore)

    weak var delegate: TokenViewControllerDelegate?

    init(session: WalletSession, tokensDataStore: TokensDataStore, assetDefinition: AssetDefinitionStore, transactionType: TransactionType, analyticsCoordinator: AnalyticsCoordinator, token: TokenObject) {
        self.token = token
        self.session = session
        self.tokensDataStore = tokensDataStore
        self.assetDefinitionStore = assetDefinition
        self.transactionType = transactionType
        self.analyticsCoordinator = analyticsCoordinator

        super.init(nibName: nil, bundle: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        print("TokenViewController")
        self.setupBtn()
        self.setupTableView()
        self.setupTap()
        self.configureBalanceViewModel()
        self.setupLabel()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupTableView() {
        self.tableView.register(TokenViewControllerTransactionCell.self)
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.tableFooterView = UIView.tableFooterToRemoveEmptyCellSeparators()
    }
    
    func setupBtn() {
        self.sendBtn.layer.cornerRadius = 8.0
        self.receiveBtn.layer.cornerRadius = 8.0
        self.receiveBtn.layer.borderWidth = 1.0
        self.receiveBtn.layer.borderColor = Colors.tbakeDarkBrown.cgColor
        
        self.sendBtn.addTarget(self, action: #selector(self.doSend), for: .touchUpInside)
        self.receiveBtn.addTarget(self, action: #selector(self.doReceive), for: .touchUpInside)
        
        self.sendBtn.setTitle(self.viewModel?.sendButtonTitle, for: .normal)
        self.receiveBtn.setTitle(self.viewModel?.receiveButtonTitle, for: .normal)
    }
    
    func setupTap() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(showContractWebPage))
        self.tokenImgView.addGestureRecognizer(tap)
    }
    
    func setupLabel() {
        self.recentTransactionLbl.text = R.string.localizable.recentTransactions()
    }
    
    func configure(viewModel: TokenViewControllerViewModel) {
        self.viewModel = viewModel
    }

    private func configureBalanceViewModel() {
        switch transactionType {
        case .nativeCryptocurrency:
            session.balanceViewModel.subscribe { [weak self] viewModel in
                guard let self = self, let viewModel = viewModel else { return }
                let amount = viewModel.amountShort
                self.tokenNameAndAmountLbl.text = "\(amount) \(viewModel.symbol)"
                self.tokenImgView.image = self.headerViewModel.iconImage.value?.image
            }
            session.refresh(.ethBalance)
        case .ERC20Token(let token, _, _):
            let amount = EtherNumberFormatter.short.string(from: token.valueBigInt, decimals: token.decimals)
            //Note that if we want to display the token name directly from token.name, we have to be careful that DAI token's name has trailing \0
            self.tokenNameAndAmountLbl.text = "\(amount) \(token.symbolInPluralForm(withAssetDefinitionStore: assetDefinitionStore))"
            self.tokenImgView.image = self.headerViewModel.iconImage.value?.image
        case .ERC875Token, .ERC875TokenOrder, .ERC721Token, .ERC721ForTicketToken, .dapp, .tokenScript, .claimPaidErc875MagicLink:
            break
        }

        self.title = token.symbol
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
        guard let tokenObject = viewModel?.token else { return nil }
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
                    guard let strongSelf = self else { return }
                    guard let viewModel = strongSelf.viewModel else { return }
                    strongSelf.configure(viewModel: viewModel)
                }
            }
        }

        let token = Token(tokenIdOrEvent: .tokenId(tokenId: hardcodedTokenIdForFungibles), tokenType: tokenObject.type, index: 0, name: tokenObject.name, symbol: tokenObject.symbol, status: .available, values: values)
        tokenHolder = TokenHolder(tokens: [token], contractAddress: tokenObject.contractAddress, hasAssetDefinition: true)
        return tokenHolder
    }
}

extension TokenViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: TokenViewControllerTransactionCell = tableView.dequeueReusableCell(for: indexPath)
        if let transaction = viewModel?.recentTransactions[indexPath.row] {
            let viewModel = TokenViewControllerTransactionCellViewModel(
                    transaction: transaction,
                    config: session.config,
                    chainState: session.chainState,
                    currentWallet: session.account
            )
            cell.configure(viewModel: viewModel)
        } else {
            cell.configureEmpty()
        }
        return cell
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel?.recentTransactions.count ?? 0
    }
}

extension TokenViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let transaction = viewModel?.recentTransactions[indexPath.row] else { return }
        delegate?.didTap(transaction: transaction, inViewController: self)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 90
    }
}

extension TokenViewController: CanOpenURL2 {
    func open(url: URL) {
        delegate?.didPressOpenWebPage(url, in: self)
    }
}

// MARK: Analytics
extension TokenViewController {
    private func logStartOnRamp(name: String) {
        analyticsCoordinator.log(navigation: Analytics.Navigation.onRamp, properties: [Analytics.Properties.name.rawValue: name])
    }
}
