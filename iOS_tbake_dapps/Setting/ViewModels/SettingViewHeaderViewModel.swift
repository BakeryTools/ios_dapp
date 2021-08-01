//
//  SettingViewHeaderViewModel.swift
//  AlphaWallet
//
//  Created by Vladyslav Shepitko on 02.06.2020.
//

import UIKit

struct SettingViewHeaderViewModel {
    let titleText: String
    var detailsText: String?
    var titleTextFont: UIFont
    var showTopSeparator: Bool = true

    var titleTextColor: UIColor {
        return Screen.TokenCard.Color.grayLabel
    }

    var detailsTextColor: UIColor {
        return Screen.TokenCard.Color.grayLabel
    }
    var detailsTextFont: UIFont {
        return Screen.TokenCard.Font.subtitle
    }

    var backgroundColor: UIColor {
        return Colors.backgroundClear
    }

    var separatorColor: UIColor {
        return Screen.TokenCard.Color.grayLabel
    }
}

extension SettingViewHeaderViewModel {
    init(section: SettingsSection) {
        titleText = section.title
        switch section {
        case .tokenStandard(let value), .version(let value):
            detailsText = value
            titleTextFont = Screen.TokenCard.Font.subtitle
            if case .tokenStandard = section {
                showTopSeparator = false
            }
        case .wallet, .system, .community:
            titleTextFont = Screen.TokenCard.Font.blockChainName
        }
    }
}
