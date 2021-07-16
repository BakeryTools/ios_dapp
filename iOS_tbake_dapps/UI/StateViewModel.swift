// Copyright SIX DAY LLC. All rights reserved.

import Foundation
import UIKit

struct StateViewModel {

    var titleTextColor: UIColor {
        return Colors.appText
   }

    var titleFont: UIFont {
        return Fonts.semibold(size: 18)
    }

    var descriptionTextColor: UIColor {
        return Colors.appText
    }

    var descriptionFont: UIFont {
        return Fonts.regular(size: 16)
    }

    var stackSpacing: CGFloat {
        return 30
    }
}
