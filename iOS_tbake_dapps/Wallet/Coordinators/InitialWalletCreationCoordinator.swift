// Copyright SIX DAY LLC. All rights reserved.

import Foundation
import UIKit

protocol InitialWalletCreationCoordinatorDelegate: AnyObject {
    func didCancel(in coordinator: InitialWalletCreationCoordinator)
    func didAddAccount(_ account: Wallet, comeFrom: String, in coordinator: InitialWalletCreationCoordinator)
}

class InitialWalletCreationCoordinator: Coordinator {
    private let keystore: Keystore
    private let config: Config
    private let analyticsCoordinator: AnalyticsCoordinator

    let navigationController: UINavigationController
    var coordinators: [Coordinator] = []
    weak var delegate: InitialWalletCreationCoordinatorDelegate?

    init(
        config: Config,
        navigationController: UINavigationController,
        keystore: Keystore,
        analyticsCoordinator: AnalyticsCoordinator
    ) {
        self.config = config
        self.navigationController = navigationController
        self.keystore = keystore
        self.analyticsCoordinator = analyticsCoordinator

        navigationController.setNavigationBarHidden(true, animated: true)
    }

    func start() {
        let coordinator = WalletCoordinator(config: config, navigationController: navigationController, keystore: keystore, analyticsCoordinator: analyticsCoordinator)
        coordinator.delegate = self
        coordinator.start(.addInitialWallet)

        addCoordinator(coordinator)
    }
}

extension InitialWalletCreationCoordinator: WalletCoordinatorDelegate {
    func didFinish(comeFrom: String, with account: Wallet, in coordinator: WalletCoordinator) {
        navigationController.setNavigationBarHidden(true, animated: true)

        delegate?.didAddAccount(account, comeFrom: comeFrom, in: self)
        removeCoordinator(coordinator)
    }

    func didCancel(in coordinator: WalletCoordinator) {
        navigationController.setNavigationBarHidden(true, animated: true)

        delegate?.didCancel(in: self)
        removeCoordinator(coordinator)
    }
}
