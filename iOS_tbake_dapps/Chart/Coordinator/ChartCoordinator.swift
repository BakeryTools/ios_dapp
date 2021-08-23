//
//  ChartCoordinator.swift
//  iOS_tbake_dapps
//
//  Created by Danial on 04/08/2021.
//

import UIKit
import WebKit
import APIKit
import BigInt
import JSONRPCKit
import PromiseKit
import RealmSwift
import Result

protocol ChartCoordinatorDelegate: AnyObject, CanOpenURL {
    func openPage(url: URL?, forceReload: Bool)
    func didSentTransaction(transaction: SentTransaction, inCoordinator coordinator: ChartCoordinator)
    func importUniversalLink(url: URL, forCoordinator coordinator: ChartCoordinator)
    func handleUniversalLink(_ url: URL, forCoordinator coordinator: ChartCoordinator)
    func handleCustomUrlScheme(_ url: URL, forCoordinator coordinator: ChartCoordinator)
    func restartToAddEnableAndSwitchBrowserToServer(inCoordinator coordinator: ChartCoordinator)
    func restartToEnableAndSwitchBrowserToServer(inCoordinator coordinator: ChartCoordinator)
}

final class ChartCoordinator: NSObject, Coordinator {
    private var session: WalletSession {
        return sessions[server]
    }
    private let sessions: ServerDictionary<WalletSession>
    private let keystore: Keystore
    private let config: Config
    private let analyticsCoordinator: AnalyticsCoordinator

    private let sharedRealm: Realm
    private let browserOnly: Bool
    private let nativeCryptoCurrencyPrices: ServerDictionary<Subscribable<Double>>
    private let restartQueue: RestartTaskQueue

    lazy var rootViewController: ChartViewController = {
        let vc = ChartViewController(account: session.account, server: server)
        vc.delegate = self
        vc.webView.uiDelegate = self
        return vc
    }()

    private lazy var preferences: PreferencesController = {
        return PreferencesController()
    }()

    private var urlParser: BrowserURLParser {
        return BrowserURLParser()
    }

    private var server: RPCServer {
        get {
            let selected = RPCServer(chainID: Config.getChainId())
            let enabled = config.enabledServers
            if enabled.contains(selected) {
                return selected
            } else {
                let fallback = enabled[0]
                Config.setChainId(fallback.chainID)
                return fallback
            }
        }
        set {
            Config.setChainId(newValue.chainID)
        }
    }

    private var currentUrl: URL? {
        return rootViewController.webView.url
    }

    var coordinators: [Coordinator] = []
    let navigationController =  UINavigationController()

    weak var delegate: ChartCoordinatorDelegate?

   init(
        sessions: ServerDictionary<WalletSession>,
        keystore: Keystore,
        config: Config,
        sharedRealm: Realm,
        browserOnly: Bool,
        nativeCryptoCurrencyPrices: ServerDictionary<Subscribable<Double>>,
        restartQueue: RestartTaskQueue,
        analyticsCoordinator: AnalyticsCoordinator
    ) {
        self.sessions = sessions
        self.keystore = keystore
        self.config = config
        self.sharedRealm = sharedRealm
        self.browserOnly = browserOnly
        self.nativeCryptoCurrencyPrices = nativeCryptoCurrencyPrices
        self.restartQueue = restartQueue
        self.analyticsCoordinator = analyticsCoordinator

        super.init()
    }

    func start() {
        navigationController.viewControllers = [rootViewController]
        self.open(url: "")
    }

    @objc func dismiss() {
        removeAllCoordinators()
        navigationController.dismiss(animated: true)
    }

    private enum PendingTransaction {
        case none
        case data(callbackID: Int)
    }

    private var pendingTransaction: PendingTransaction = .none

    private func executeTransaction(account: TBakeWallet.Address, action: DappAction, callbackID: Int, transaction: UnconfirmedTransaction, type: ConfirmType, server: RPCServer) {
        pendingTransaction = .data(callbackID: callbackID)
        let ethPrice = nativeCryptoCurrencyPrices[server]
        let coordinator = TransactionConfirmationCoordinator(presentingViewController: navigationController, session: session, transaction: transaction, configuration: .dappTransaction(confirmType: type, keystore: keystore, ethPrice: ethPrice), analyticsCoordinator: analyticsCoordinator)
        coordinator.delegate = self
        addCoordinator(coordinator)
        coordinator.start(fromSource: .browser)
    }

    private func ethCall(callbackID: Int, from: TBakeWallet.Address?, to: TBakeWallet.Address?, data: String, server: RPCServer) {
        let request = EthCallRequest(from: from, to: to, data: data)
        firstly {
            Session.send(EtherServiceRequest(server: server, batch: BatchFactory().create(request)))
        }.done { result in
            let callback = DappCallback(id: callbackID, value: .ethCall(result))
            self.rootViewController.notifyFinish(callbackID: callbackID, value: .success(callback))
        }.catch { error in
            if case let SessionTaskError.responseError(JSONRPCError.responseError(_, message: message, _)) = error {
                self.rootViewController.notifyFinish(callbackID: callbackID, value: .failure(.nodeError(message)))
            } else {
                //TODO better handle. User didn't cancel
                self.rootViewController.notifyFinish(callbackID: callbackID, value: .failure(.cancelled))
            }
        }
    }

    func open(url: String) {
        rootViewController.urlSetup(urlString: url)
    }

    func signMessage(with type: SignMessageType, account: TBakeWallet.Address, callbackID: Int) {
        firstly {
            SignMessageCoordinator.promise(analyticsCoordinator: analyticsCoordinator, navigationController: navigationController, keystore: keystore, coordinator: self, signType: type, account: account, source: .dappBrowser)
        }.done { data in
            let callback: DappCallback
            switch type {
            case .message:
                callback = DappCallback(id: callbackID, value: .signMessage(data))
            case .personalMessage:
                callback = DappCallback(id: callbackID, value: .signPersonalMessage(data))
            case .typedMessage:
                callback = DappCallback(id: callbackID, value: .signTypedMessage(data))
            case .eip712v3And4:
                callback = DappCallback(id: callbackID, value: .signTypedMessageV3(data))
            }

            self.rootViewController.notifyFinish(callbackID: callbackID, value: .success(callback))
        }.catch { _ in
            self.rootViewController.notifyFinish(callbackID: callbackID, value: .failure(DAppError.cancelled))
        }
    }
    
    func `switch`(toServer server: RPCServer, url: URL? = nil) {
        self.server = server
        start()

        open(url: url?.absoluteString ?? "")
    }

    private func share(sender: UIView) {
        logShare()
        guard let url = currentUrl else { return }
        rootViewController.displayLoading()
        rootViewController.showShareActivity(fromSource: .view(sender), with: [url]) { [weak self] in
            guard let self = self else { return }
            self.rootViewController.hideLoading()
        }
    }

    func isMagicLink(_ url: URL) -> Bool {
        return RPCServer.allCases.contains { $0.magicLinkHost == url.host }
    }

    private func addCustomWallet(callbackID: Int, customChain: WalletAddEthereumChainObject, inViewController viewController: UIViewController) {
        let coordinator = DappRequestSwitchCustomChainCoordinator(config: config, server: server, callbackId: callbackID, customChain: customChain, restartQueue: restartQueue, analyticsCoordinator: analyticsCoordinator, currentUrl: currentUrl, inViewController: viewController)
        coordinator.delegate = self
        addCoordinator(coordinator)
        coordinator.start()
    }
}

extension ChartCoordinator: TransactionConfirmationCoordinatorDelegate {

    func coordinator(_ coordinator: TransactionConfirmationCoordinator, didFailTransaction error: AnyError) {
        coordinator.close { [weak self] in
            guard let strongSelf = self else { return }

            switch strongSelf.pendingTransaction {
            case .data(let callbackID):
                strongSelf.rootViewController.notifyFinish(callbackID: callbackID, value: .failure(DAppError.cancelled))
            case .none:
                break
            }

            strongSelf.removeCoordinator(coordinator)
            strongSelf.navigationController.dismiss(animated: true)
        }
    }

    func didClose(in coordinator: TransactionConfirmationCoordinator) {
        switch pendingTransaction {
        case .data(let callbackID):
            rootViewController.notifyFinish(callbackID: callbackID, value: .failure(DAppError.cancelled))
        case .none:
            break
        }

        removeCoordinator(coordinator)
        navigationController.dismiss(animated: true)
    }

    func coordinator(_ coordinator: TransactionConfirmationCoordinator, didCompleteTransaction result: TransactionConfirmationResult) {
        coordinator.close { [weak self] in
            guard let strongSelf = self, let delegate = strongSelf.delegate else { return }

            switch (strongSelf.pendingTransaction, result) {
            case (.data(let callbackID), .confirmationResult(let type)):
                switch type {
                case .signedTransaction(let data):
                    let callback = DappCallback(id: callbackID, value: .signTransaction(data))
                    strongSelf.rootViewController.notifyFinish(callbackID: callbackID, value: .success(callback))
                    //TODO do we need to do this for a pending transaction?
    //                    strongSelf.delegate?.didSentTransaction(transaction: transaction, inCoordinator: strongSelf)
                case .sentTransaction(let transaction):
                    // on send transaction we pass transaction ID only.
                    let data = Data(_hex: transaction.id)
                    let callback = DappCallback(id: callbackID, value: .sentTransaction(data))
                    strongSelf.rootViewController.notifyFinish(callbackID: callbackID, value: .success(callback))

                    delegate.didSentTransaction(transaction: transaction, inCoordinator: strongSelf)
                case .sentRawTransaction:
                    break
                }
            case (.none, .noData), (.none, .confirmationResult), (.data, .noData):
                break
            }

            strongSelf.removeCoordinator(coordinator)
            strongSelf.navigationController.dismiss(animated: true)
        }
    }
}

extension ChartCoordinator: ChartViewControllerDelegate {
    func openPage(url: URL?, forceReload: Bool) {
        self.delegate?.openPage(url: url, forceReload: forceReload)
    }
    
    func didCall(action: DappAction, callbackID: Int, inBrowserViewController viewController: ChartViewController) {
        guard case .real(let account) = session.account.type else {
            rootViewController.notifyFinish(callbackID: callbackID, value: .failure(DAppError.cancelled))
            navigationController.topViewController?.displayError(error: InCoordinatorError.onlyWatchAccount)
            return
        }

        switch action {
        case .signTransaction(let unconfirmedTransaction):
            executeTransaction(account: account, action: action, callbackID: callbackID, transaction: unconfirmedTransaction, type: .signThenSend, server: server)
        case .sendTransaction(let unconfirmedTransaction):
            executeTransaction(account: account, action: action, callbackID: callbackID, transaction: unconfirmedTransaction, type: .signThenSend, server: server)
        case .signMessage(let hexMessage):
            signMessage(with: .message(hexMessage.toHexData), account: account, callbackID: callbackID)
        case .signPersonalMessage(let hexMessage):
            signMessage(with: .personalMessage(hexMessage.toHexData), account: account, callbackID: callbackID)
        case .signTypedMessage(let typedData):
            signMessage(with: .typedMessage(typedData), account: account, callbackID: callbackID)
        case .signTypedMessageV3(let typedData):
            signMessage(with: .eip712v3And4(typedData), account: account, callbackID: callbackID)
        case .ethCall(from: let from, to: let to, data: let data):
            //Must use unchecked form for `Address `because `from` and `to` might be 0x0..0. We assume the dapp author knows what they are doing
            let from = TBakeWallet.Address(uncheckedAgainstNullAddress: from)
            let to = TBakeWallet.Address(uncheckedAgainstNullAddress: to)
            ethCall(callbackID: callbackID, from: from, to: to, data: data, server: server)
        case .walletAddEthereumChain(let customChain):
            addCustomWallet(callbackID: callbackID, customChain: customChain, inViewController: viewController)
        case .unknown, .sendRawTransaction:
            break
        }
    }
}


extension ChartCoordinator: WKUIDelegate {
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil {
            rootViewController.webView.load(navigationAction.request)
        }
        return nil
    }

    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let alertController = UIAlertController.alertController(
            title: .none,
            message: message,
            style: .alert,
            in: navigationController
        )
        alertController.addAction(UIAlertAction(title: R.string.localizable.oK(), style: .default, handler: { _ in
            completionHandler()
        }))
        navigationController.present(alertController, animated: true, completion: nil)
    }

    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        let alertController = UIAlertController.alertController(
            title: .none,
            message: message,
            style: .alert,
            in: navigationController
        )
        alertController.addAction(UIAlertAction(title: R.string.localizable.oK(), style: .default, handler: { _ in
            completionHandler(true)
        }))
        alertController.addAction(UIAlertAction(title: R.string.localizable.cancel(), style: .default, handler: { _ in
            completionHandler(false)
        }))
        navigationController.present(alertController, animated: true, completion: nil)
    }

    func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
        let alertController = UIAlertController.alertController(
            title: .none,
            message: prompt,
            style: .alert,
            in: navigationController
        )
        alertController.addTextField { (textField) in
            textField.text = defaultText
        }
        alertController.addAction(UIAlertAction(title: R.string.localizable.oK(), style: .default, handler: { _ in
            if let text = alertController.textFields?.first?.text {
                completionHandler(text)
            } else {
                completionHandler(defaultText)
            }
        }))
        alertController.addAction(UIAlertAction(title: R.string.localizable.cancel(), style: .default, handler: { _ in
            completionHandler(nil)
        }))
        navigationController.present(alertController, animated: true, completion: nil)
    }
}

extension ChartCoordinator: CanOpenURL {
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

// MARK: Analytics
extension ChartCoordinator {
    private func logReload() {
        analyticsCoordinator.log(action: Analytics.Action.reloadBrowser)
    }

    private func logShare() {
        analyticsCoordinator.log(action: Analytics.Action.shareUrl, properties: [Analytics.Properties.source.rawValue: "browser"])
    }

    private func logAddDapp() {
        analyticsCoordinator.log(action: Analytics.Action.addDapp)
    }

    private func logSwitchServer() {
        analyticsCoordinator.log(navigation: Analytics.Navigation.switchServers, properties: [Analytics.Properties.source.rawValue: "browser"])
    }

    private func logShowDapps() {
        analyticsCoordinator.log(navigation: Analytics.Navigation.showDapps)
    }

    private func logShowHistory() {
        analyticsCoordinator.log(navigation: Analytics.Navigation.showHistory)
    }

    private func logTapMore() {
        analyticsCoordinator.log(navigation: Analytics.Navigation.tapBrowserMore)
    }

    private func logEnterUrl() {
        analyticsCoordinator.log(action: Analytics.Action.enterUrl)
    }
}

extension ChartCoordinator: DappRequestSwitchCustomChainCoordinatorDelegate {
    func notifySuccessful(withCallbackId callbackId: Int, inCoordinator coordinator: DappRequestSwitchCustomChainCoordinator) {
        let callback = DappCallback(id: callbackId, value: .walletAddEthereumChain)
        rootViewController.notifyFinish(callbackID: callbackId, value: .success(callback))
        removeCoordinator(coordinator)
    }

    func switchBrowserToExistingServer(_ server: RPCServer, url: URL?, inCoordinator coordinator: DappRequestSwitchCustomChainCoordinator) {
        `switch`(toServer: server, url: url)
        removeCoordinator(coordinator)
    }

    func restartToEnableAndSwitchBrowserToServer(inCoordinator coordinator: DappRequestSwitchCustomChainCoordinator) {
        delegate?.restartToEnableAndSwitchBrowserToServer(inCoordinator: self)
        removeCoordinator(coordinator)
    }

    func restartToAddEnableAndSwitchBrowserToServer(inCoordinator coordinator: DappRequestSwitchCustomChainCoordinator) {
        delegate?.restartToAddEnableAndSwitchBrowserToServer(inCoordinator: self)
        removeCoordinator(coordinator)
    }

    func userCancelled(withCallbackId callbackId: Int, inCoordinator coordinator: DappRequestSwitchCustomChainCoordinator) {
        rootViewController.notifyFinish(callbackID: callbackId, value: .failure(DAppError.cancelled))
        removeCoordinator(coordinator)
    }

    func failed(withErrorMessage errorMessage: String, withCallbackId callbackId: Int, inCoordinator coordinator: DappRequestSwitchCustomChainCoordinator) {
        let error = DAppError.nodeError(errorMessage)
        rootViewController.notifyFinish(callbackID: callbackId, value: .failure(error))
        removeCoordinator(coordinator)
    }

    func failed(withError error: DAppError, withCallbackId callbackId: Int, inCoordinator coordinator: DappRequestSwitchCustomChainCoordinator) {
        rootViewController.notifyFinish(callbackID: callbackId, value: .failure(error))
        removeCoordinator(coordinator)
    }

    func cleanup(coordinator: DappRequestSwitchCustomChainCoordinator) {
        removeCoordinator(coordinator)
    }
}
