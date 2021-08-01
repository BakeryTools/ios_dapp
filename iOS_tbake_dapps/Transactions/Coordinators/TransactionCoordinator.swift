// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import PromiseKit
import Result

protocol TransactionCoordinatorDelegate: AnyObject, CanOpenURL {
}

class TransactionCoordinator: Coordinator {
    private let analyticsCoordinator: AnalyticsCoordinator
    private let keystore: Keystore
    private let transactionsCollection: TransactionCollection
    private let promptBackupCoordinator: PromptBackupCoordinator
    private let sessions: ServerDictionary<WalletSession>
    private let tokensStorages: ServerDictionary<TokensDataStore>

    lazy var rootViewController: TransactionsViewController = {
        return makeTransactionsController()
    }()

    lazy var dataCoordinator: TransactionDataCoordinator = {
        let coordinator = TransactionDataCoordinator(
            sessions: sessions,
            transactionCollection: transactionsCollection,
            keystore: keystore,
            tokensStorages: tokensStorages,
            promptBackupCoordinator: promptBackupCoordinator
        )
        return coordinator
    }()

    weak var delegate: TransactionCoordinatorDelegate?
    let navigationController: UINavigationController
    var coordinators: [Coordinator] = []

    init(
        analyticsCoordinator: AnalyticsCoordinator,
        sessions: ServerDictionary<WalletSession>,
        navigationController: UINavigationController = UINavigationController(),
        transactionsCollection: TransactionCollection,
        keystore: Keystore,
        tokensStorages: ServerDictionary<TokensDataStore>,
        promptBackupCoordinator: PromptBackupCoordinator
    ) {
        self.analyticsCoordinator = analyticsCoordinator
        self.sessions = sessions
        self.keystore = keystore
        self.navigationController = navigationController
        self.transactionsCollection = transactionsCollection
        self.tokensStorages = tokensStorages
        self.promptBackupCoordinator = promptBackupCoordinator

        NotificationCenter.default.addObserver(self, selector: #selector(didEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
    }

    func start() {
        navigationController.viewControllers = [rootViewController]
    }

    private func makeTransactionsController() -> TransactionsViewController {
        let viewModel = TransactionsViewModel()
        let controller = TransactionsViewController(
            dataCoordinator: dataCoordinator,
            sessions: sessions,
            viewModel: viewModel
        )
        controller.delegate = self
        return controller
    }

    private func showTransaction(_ transactionRow: TransactionRow, on navigationController: UINavigationController) {
        let viewController = TransactionViewController(analyticsCoordinator: analyticsCoordinator, session: sessions[transactionRow.server], transactionRow: transactionRow, delegate: self)

        viewController.navigationItem.largeTitleDisplayMode = .never
        viewController.hidesBottomBarWhenPushed = true
        
        navigationController.pushViewController(viewController, animated: true)
    }

    //TODO duplicate of method showTransaction(_:) to display in a specific UIViewController because we are now showing transactions from outside the transactions tab. Clean up
    func showTransaction(_ transactionRow: TransactionRow, inViewController viewController: UIViewController) {
        guard let navigationController = viewController.navigationController else { return }
        showTransaction(transactionRow, on: navigationController)
    }

    func showTransaction(withId transactionId: String, server: RPCServer, inViewController viewController: UIViewController) {
        //Quite likely we should have the transaction already
        //TODO handle when we don't handle the transaction, so we must fetch it. There might not be a simple API call to just fetch a single transaction. Probably have to fetch all transactions in a single block with Etherscan?
        guard let transaction = transactionsCollection.transaction(withTransactionId: transactionId, server: server) else { return }
        if transaction.localizedOperations.count > 1 {
            showTransaction(.group(transaction), inViewController: viewController)
        } else {
            showTransaction(.standalone(transaction), inViewController: viewController)
        }
    }

    @objc func didEnterForeground() {
        rootViewController.fetch()
    }

    func stop() {
        dataCoordinator.stop()
        //TODO seems not good to stop here because others call stop too
        for each in sessions.values {
            each.stop()
        }
    }
}

extension TransactionCoordinator: TransactionsViewControllerDelegate {
    func didPressTransaction(transactionRow: TransactionRow, in viewController: TransactionsViewController) {
        showTransaction(transactionRow, on: navigationController)
    }
}

extension TransactionCoordinator: CanOpenURL {
    func didPressViewContractWebPage(forContract contract: TBakeWallet.Address, server: RPCServer, in viewController: UIViewController) {
        delegate?.didPressViewContractWebPage(forContract: contract, server: server, in: viewController)
    }

    func didPressViewContractWebPage(_ url: URL, in viewController: UIViewController) {
        delegate?.didPressViewContractWebPage(url, in: viewController)
    }

    func didPressOpenWebPage(_ url: URL, in viewController: UIViewController) {
        delegate?.didPressOpenWebPage(url, in: viewController)
    }
}

extension TransactionCoordinator: TransactionViewControllerDelegate {
}
