//
//  WalletSummaryTableViewCellViewModel.swift
//  iOS_tbake_dapps
//
//  Created by Danial on 22/07/2021.
//

import UIKit

struct WalletSummaryTableViewCellViewModel {
    private let summary: WalletSummary?

    init(summary: WalletSummary?) {
        self.summary = summary
    }

    var balanceAttributedString: NSAttributedString {
        return .init(string: summary?.totalAmount ?? "--", attributes: [
            .font: Screen.TokenCard.Font.title,
            .foregroundColor: Screen.TokenCard.Color.title,
        ])
    }

    var apprecation24HoursAttributedString: NSAttributedString {
        let apprecation = todaysApprecation
        return .init(string: apprecation.0, attributes: [
            .font: Screen.TokenCard.Font.subtitle,
            .foregroundColor: apprecation.1,
        ])
    }

    private var todaysApprecation: (String, UIColor) {
        let valueChangeValue: String = {
            if let value = summary?.changeDouble {
                return NumberFormatter.usd.string(from: value) ?? "-"
            } else {
                return "-"
            }
        }()

        var valuePercentageChangeValue: String {
            switch BalanceHelper().change24h(from: summary?.changePercentage) {
            case .appreciate(let percentageChange24h):
                return "(+ \(percentageChange24h)%)"
            case .depreciate(let percentageChange24h):
                return "(\(percentageChange24h)%)"
            case .none:
                return "-"
            }
        }
        
        let value = R.string.localizable.walletSummaryToday(valueChangeValue + " " + valuePercentageChangeValue)
        return (value, BalanceHelper().valueChangeValueColor(from: summary?.changePercentage))
    }

    var accessoryType: UITableViewCell.AccessoryType {
        return .disclosureIndicator
    }

    var backgroundColor: UIColor {
        return Colors.backgroundClear
    }
}
