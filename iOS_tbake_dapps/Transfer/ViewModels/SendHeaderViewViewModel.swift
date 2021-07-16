// Copyright © 2018 Stormbird PTE. LTD.

import UIKit

struct SendHeaderViewViewModel {
    private let token: TokenObject
    private let transactionType: TransactionType
    let server: RPCServer
    var title: String
    var ticker: CoinTicker?
    var currencyAmount: String?
    var isShowingValue: Bool = true

    init(server: RPCServer, token: TokenObject, transactionType: TransactionType) {
        self.server = server
        self.token = token
        self.transactionType = transactionType
        title = ""
        ticker = nil
        currencyAmount = nil
    }

    private var valuePercentageChangeValue: String? {
        switch EthCurrencyHelper(ticker: ticker).change24h {
        case .appreciate(let percentageChange24h):
            return "(\(percentageChange24h)%)"
        case .depreciate(let percentageChange24h):
            return "(\(percentageChange24h)%)"
        case .none:
            return nil
        }
    }

    var backgroundColor: UIColor {
        return Colors.backgroundClear
    }

    var iconImage: Subscribable<TokenImage> {
        token.icon
    }

    var blockChainTagViewModel: BlockchainTagLabelViewModel {
        .init(server: server)
    }

    var titleAttributedString: NSAttributedString {
        return NSAttributedString(string: title, attributes: [
            .font: Screen.TokenCard.Font.title,
            .foregroundColor: Screen.TokenCard.Color.title,
        ])
    }

    var valueAttributedString: NSAttributedString? {
        if server.isTestnet {
            return nil
        } else {
            switch transactionType {
            case .nativeCryptocurrency:
                if isShowingValue {
                    return nil //tokenValueAttributedString
                } else {
                    return nil //marketPriceAttributedString
                }
            case .ERC20Token, .ERC875Token, .ERC875TokenOrder, .ERC721Token, .ERC721ForTicketToken, .dapp, .tokenScript, .claimPaidErc875MagicLink:
                return nil
            }
        }
    }

    private var tokenValueAttributedString: NSAttributedString? {
        let string = R.string.localizable.aWalletTokenValue(currencyAmount ?? "-")

        return NSAttributedString(string: string, attributes: [
            .font: Screen.TokenCard.Font.placeholderLabel,
            .foregroundColor: Screen.TokenCard.Color.valueChangeLabel
        ])
    }

    private var marketPriceAttributedString: NSAttributedString? {
        guard let marketPrice = marketPriceValue, let valuePercentageChange = valuePercentageChangeValue else {
            return nil
        }

        let string = R.string.localizable.aWalletTokenMarketPrice(marketPrice, valuePercentageChange)

        guard let valuePercentageChangeRange = string.range(of: valuePercentageChange) else { return nil }

        let mutableAttributedString = NSMutableAttributedString(string: string, attributes: [
            .font: Screen.TokenCard.Font.placeholderLabel,
            .foregroundColor: Screen.TokenCard.Color.valueChangeLabel
        ])

        let range = NSRange(valuePercentageChangeRange, in: string)
        mutableAttributedString.setAttributes([
            .font: Screen.TokenCard.Font.blockChainName,
            .foregroundColor: Screen.TokenCard.Color.valueChangeValue(ticker: ticker)
        ], range: range)

        return mutableAttributedString
    }

    private var marketPriceValue: String? {
        if let value = EthCurrencyHelper(ticker: ticker).marketPrice {
            return NumberFormatter.usd.string(from: value)
        } else {
            return nil
        }
    }
}
