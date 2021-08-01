//
//  settingModel.swift
//  AlphaWallet
//
//  Created by Nimit Parekh on 06/04/20.
//

import UIKit

struct SettingTableViewCellViewModel {
    let titleText: String
    var subTitleText: String?
    let icon: UIImage

    var subTitleHidden: Bool {
        return subTitleText == nil
    }

    var titleFont: UIFont {
        return Screen.TokenCard.Font.title
    }

    var titleTextColor: UIColor {
        return Screen.TokenCard.Color.title
    }

    var subTitleFont: UIFont {
        return Screen.TokenCard.Font.subtitle
    }

    var subTitleTextColor: UIColor {
        return Screen.TokenCard.Color.grayLabel
    }
}

extension SettingTableViewCellViewModel {
    init(settingsSystemRow row: SettingsSystemRow) {
        titleText = row.title
        icon = row.icon
    }

    init(settingsWalletRow row: SettingsWalletRow) {
        titleText = row.title
        icon = row.icon
    }
}
