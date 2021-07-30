// Copyright © 2018 Stormbird PTE. LTD.

import Foundation
import UIKit.UIColor

class EthCurrencyHelper {
    enum Change24h {
        case appreciate(percentageChange24h: Double)
        case depreciate(percentageChange24h: Double)
        case none
    }
    private var ticker: CoinTicker?

    var change24h: Change24h {
        if let value = percentageChange24h {
            if isValueAppreciated24h {
                return .appreciate(percentageChange24h: value)
            } else if isValueDepreciated24h {
                return .depreciate(percentageChange24h: value)
            } else {
                return .none
            }
        } else {
            return .none
        }
    }

    var marketPrice: Double? {
        return ticker?.price_usd
    }

    func valueChanged24h(value: NSDecimalNumber?) -> Double? {
        guard let fiatValue = fiatValue(value: value), let ticker = ticker else { return .none }

        return fiatValue * ticker.percent_change_24h / 100
    }

    func fiatValue(value: NSDecimalNumber?) -> Double? {
        guard let value = value, let ticker = ticker else { return .none }

        return value.doubleValue * ticker.price_usd
    }

    private var percentageChange24h: Double? {
        if let percent_change_24h = ticker?.percent_change_24h {
            return percent_change_24h.rounded(to: 2)
        } else {
            return nil
        }
    }

    private var isValueAppreciated24h: Bool {
        if let percentChange = percentageChange24h {
            return percentChange > 0
        } else {
            return false
        }
    }

    private var isValueDepreciated24h: Bool {
        if let percentChange = percentageChange24h {
            return percentChange < 0
        } else {
            return false
        }
    }

    init(ticker: CoinTicker?) {
        self.ticker = ticker
    }
}

class BalanceHelper {
    
    enum Change24h {
        case appreciate(percentageChange24h: Double)
        case depreciate(percentageChange24h: Double)
        case none
    }

    func change24h(from value: Double?) -> Change24h {
        if let value = value?.rounded(to: 2) {
            if isValueAppreciated24h(value) {
                return .appreciate(percentageChange24h: value)
            } else if isValueDepreciated24h(value) {
                return .depreciate(percentageChange24h: value)
            } else {
                return .none
            }
        } else {
            return .none
        }
    }

    private func isValueAppreciated24h(_ value: Double?) -> Bool {
        if let percentChange = value {
            return percentChange > 0
        } else {
            return false
        }
    }

    private func isValueDepreciated24h(_ value: Double?) -> Bool {
        if let percentChange = value {
            return percentChange < 0
        } else {
            return false
        }
    }

    func valueChangeValueColor(from value: Double?) -> UIColor {
        switch change24h(from: value) {
        case .appreciate:
            return Colors.appHighlightGreen
        case .depreciate:
            return Colors.appRed
        case .none:
            return Colors.appGrayLabel
        }
    }
}
