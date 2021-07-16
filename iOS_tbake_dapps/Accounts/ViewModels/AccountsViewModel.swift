// Copyright SIX DAY LLC. All rights reserved.

import Foundation

struct AccountsViewModel {
    private var config: Config
    private let hdWallets: [Wallet]
    private let keystoreWallets: [Wallet]
    private let watchedWallets: [Wallet]
    private let keystore: Keystore

    var sections: [AccountsSectionType] = [/*.summary,*/ .hdWallet, .keystoreWallet, .watchedWallet]
    let configuration: AccountsCoordinatorViewModel.Configuration
    var addresses: [AlphaWallet.Address] {
        return (hdWallets + keystoreWallets + watchedWallets).compactMap { $0.address }
    }

    init(keystore: Keystore, config: Config, configuration: AccountsCoordinatorViewModel.Configuration) {
        self.config = config
        self.keystore = keystore
        self.configuration = configuration
        hdWallets = keystore.wallets.filter { keystore.isHdWallet(wallet: $0) }.sorted { $0.address.eip55String < $1.address.eip55String }
        keystoreWallets = keystore.wallets.filter { keystore.isKeystore(wallet: $0) }.sorted { $0.address.eip55String < $1.address.eip55String }
        watchedWallets = keystore.wallets.filter { keystore.isWatched(wallet: $0) }.sorted { $0.address.eip55String < $1.address.eip55String }
    }

    var title: String {
        return configuration.navigationTitle
    }

    func walletName(forAccount account: Wallet) -> String? {
        let walletNames = config.walletNames
        return walletNames[account.address]
    }

    func numberOfItems(section: Int) -> Int {
        switch sections[section] {
        case .hdWallet:
            return hdWallets.count
        case .keystoreWallet:
            return keystoreWallets.count
        case .watchedWallet:
            return watchedWallets.count
        case .summary:
            return 1
        }
    }

    func canEditCell(indexPath: IndexPath) -> Bool {
        switch sections[indexPath.section] {
        case .hdWallet:
            return keystore.currentWallet != hdWallets[indexPath.row]
        case .keystoreWallet:
            return keystore.currentWallet != keystoreWallets[indexPath.row]
        case .watchedWallet:
            return keystore.currentWallet != watchedWallets[indexPath.row]
        case .summary:
            return false
        }
    }

    //We don't show the section headers unless there are 2 "types" of wallets
    private func shouldHideAllSectionHeaders() -> Bool {
        if keystoreWallets.isEmpty && watchedWallets.isEmpty {
            return true
        }
        if hdWallets.isEmpty && keystoreWallets.isEmpty {
            return true
        }
        if hdWallets.isEmpty && watchedWallets.isEmpty {
            return true
        }
        return false
    }

    func shouldHideHeader(in section: Int) -> (shouldHide: Bool, section: AccountsSectionType) {
        let shouldHideSectionHeaders = shouldHideAllSectionHeaders()
        switch sections[section] {
        case .hdWallet:
            return (hdWallets.isEmpty, .hdWallet)
        case .keystoreWallet:
            return (shouldHideSectionHeaders || keystoreWallets.isEmpty, .keystoreWallet)
        case .watchedWallet:
            return (shouldHideSectionHeaders || watchedWallets.isEmpty, .watchedWallet)
        case .summary:
            return (shouldHide: false, section: .summary)
        }
    }

    func account(for indexPath: IndexPath) -> Wallet? {
        switch sections[indexPath.section] {
        case .hdWallet:
            return hdWallets[indexPath.row]
        case .keystoreWallet:
            return keystoreWallets[indexPath.row]
        case .watchedWallet:
            return watchedWallets[indexPath.row]
        case .summary:
            return nil
        }
    } 

}

enum AccountsSectionType: Int, CaseIterable {
    case summary
    case hdWallet
    case keystoreWallet
    case watchedWallet

    var title: String {
        switch self {
        case .summary:
            return R.string.localizable.walletTypesSummary()
        case .hdWallet:
            return R.string.localizable.walletTypesHdWallets()
        case .keystoreWallet:
            return R.string.localizable.walletTypesKeystoreWallets()
        case .watchedWallet:
            return R.string.localizable.walletTypesWatchedWallets()
        }
    }
}
