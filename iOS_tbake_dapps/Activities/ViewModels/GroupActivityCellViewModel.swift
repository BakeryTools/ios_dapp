// Copyright © 2021 Stormbird PTE. LTD.

import UIKit

struct GroupActivityCellViewModel {
    enum GroupType {
        case swap
        case unknown
    }

    let groupType: GroupType

    var contentsBackgroundColor: UIColor {
        Colors.appBackground
    }

    var backgroundColor: UIColor {
        Colors.appBackground
    }

    var titleTextColor: UIColor {
        Colors.appText
    }

    var title: NSAttributedString {
        switch groupType {
        case .swap:
            return NSAttributedString(string: R.string.localizable.activityGroupTransactionSwap())
        case .unknown:
            return NSAttributedString(string: R.string.localizable.activityGroupTransactionUnknown())
        }
    }

    var leftMargin: CGFloat {
        StyleLayout.sideMargin
    }
}
