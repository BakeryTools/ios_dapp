//
//  GasSpeedTableViewHeaderViewModel.swift
//  AlphaWallet
//
//  Created by Vladyslav Shepitko on 25.08.2020.
//

import UIKit

struct GasSpeedTableViewHeaderViewModel {
    private let title: String

    init(title: String) {
        self.title = title
    }

    var titleAttributedString: NSAttributedString {
        return NSAttributedString(string: title, attributes: [
            .foregroundColor: Screen.TokenCard.Color.title,
            .font: Screen.TokenCard.Font.title
        ])
    }

    var backgroundColor: UIColor {
        return Colors.appBackground
    }
}
