// Copyright © 2019 Stormbird PTE. LTD.

import Foundation
import UIKit

struct CreateInitialViewModel {
    var backgroundColor: UIColor {
        return Colors.appWhite
    }

    var subtitle: String {
        return R.string.localizable.gettingStartedSubtitle()
    }

    var subtitleColor: UIColor {
        return Colors.appText
    }

    var subtitleFont: UIFont {
        if ScreenChecker().isNarrowScreen {
            return Fonts.semibold(size: 16)
        } else {
            return Fonts.semibold(size: 16)
        }
    }

    var imageViewImage: UIImage {
        return R.image.icon_splashscreen()!
    }

    var createButtonTitle: String {
        return R.string.localizable.gettingStartedNewWallet()
    }

    var importButtonTitle: String {
        return R.string.localizable.importWalletImportButtonTitle()
    }

}
