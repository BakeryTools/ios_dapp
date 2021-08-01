// Copyright © 2018 Stormbird PTE. LTD.

import Foundation
import UIKit

//Must be a class, and not a struct, otherwise changing `filter` will silently create a copy of TokensViewModel when user taps to change the filter in the UI and break filtering
class TokensViewModel {
    //Must be computed because localization can be overridden by user dynamically
    static var segmentedControlTitles: [String] { WalletFilter.orderedTabs.map { $0.title } }

    private let filterTokensCoordinator: FilterTokensCoordinator
    var tokens: [TokenObject]
    let tickers: [AddressAndRPCServer: CoinTicker]

    var filter: WalletFilter = .tokenOnly {
        didSet {
            filteredTokens = filteredAndSortedTokens()
        }
    }

    lazy var filteredTokens: [TokenObject] = {
        return filteredAndSortedTokens()
    }()

    var headerBackgroundColor: UIColor {
        return Colors.backgroundClear
    }

    var walletDefaultTitle: String {
        return R.string.localizable.walletTokensTabbarItemTitle()
    }

    var backgroundColor: UIColor {
        return Colors.backgroundClear
    }

    var shouldShowBackupPromptViewHolder: Bool {
        //TODO show the prompt in both ASSETS and COLLECTIBLES tab too
        switch filter {
        case .tokenOnly, .keyword:
            return true
        case .collectiblesOnly, .type:
            return false
        }
    }

    var shouldShowCollectiblesCollectionView: Bool {
        switch filter {
        case .tokenOnly, .keyword, .type:
            return false
        case .collectiblesOnly:
            return hasContent
        }
    }

    var hasContent: Bool {
        return !filteredTokens.isEmpty
    }

    func numberOfItems() -> Int {
        return filteredTokens.count
    }

    func item(for row: Int, section: Int) -> TokenObject {
        return filteredTokens[row]
    }

    func ticker(for token: TokenObject) -> CoinTicker? {
        return tickers[token.addressAndRPCServer]
    }

    func canDelete(for row: Int, section: Int) -> Bool {
        let token = item(for: row, section: section)
        guard !token.isInvalidated else { return false }
        if token.contractAddress.sameContract(as: Constants.nativeCryptoAddressInDatabase) {
            return false
        }
        return true
    }

    init(filterTokensCoordinator: FilterTokensCoordinator, tokens: [TokenObject], tickers: [AddressAndRPCServer: CoinTicker]) {
        self.filterTokensCoordinator = filterTokensCoordinator
        self.tokens = Self.filterAwaySpuriousTokens(tokens)
        self.tickers = tickers
    }

    //Remove tokens that look unwanted in the Wallet tab
    private static func filterAwaySpuriousTokens(_ tokens: [TokenObject]) -> [TokenObject] {
        tokens.filter { !($0.name.isEmpty && $0.symbol.isEmpty && $0.decimals == 0) }
    }

    func markTokenHidden(token: TokenObject) -> Bool {
        if let index = tokens.firstIndex(where: { $0.primaryKey == token.primaryKey }) {
            tokens.remove(at: index)
            filteredTokens = filteredAndSortedTokens()

            return true
        }

        return false
    }

    private func filteredAndSortedTokens() -> [TokenObject] {
        let displayedTokens = filterTokensCoordinator.filterTokens(tokens: tokens, filter: filter)
        return filterTokensCoordinator.sortDisplayedTokens(tokens: displayedTokens)
    }

    func nativeCryptoCurrencyToken(forServer server: RPCServer) -> TokenObject? {
        return tokens.first(where: { $0.primaryKey == TokensDataStore.etherToken(forServer: server).primaryKey })
    }

    func amount(for token: TokenObject) -> Double {
        guard let ticker = tickers[token.addressAndRPCServer], !token.valueBigInt.isZero else { return 0 }
        let tokenValue = EtherNumberFormatter.plain.string(from: token.valueBigInt, decimals: token.decimals).doubleValue
        let price = ticker.price_usd
        return tokenValue * price
    }

    func convertSegmentedControlSelectionToFilter(_ selection: SegmentedControl.Selection) -> WalletFilter? {
        switch selection {
        case .selected(let index):
            return WalletFilter.filter(fromIndex: index)
        case .unselected:
            return nil
        }
    }
}

fileprivate extension WalletFilter {
    static var orderedTabs: [WalletFilter] {
        return [
            .tokenOnly,
            .collectiblesOnly,
        ]
    }

    static func filter(fromIndex index: UInt) -> WalletFilter? {
        return WalletFilter.orderedTabs.first { $0.selectionIndex == index }
    }

    var title: String {
        switch self {
        case .tokenOnly:
            return R.string.localizable.aWalletContentsFilterTokenOnlyTitle()
        case .collectiblesOnly:
            return R.string.localizable.aWalletContentsFilterCollectiblesOnlyTitle()
        case .keyword, .type:
            return ""
        }
    }

    var selectionIndex: UInt? {
        //This is safe only because index can't possibly be negative
        return WalletFilter.orderedTabs.firstIndex { $0 == self }.flatMap { UInt($0) }
    }
}
