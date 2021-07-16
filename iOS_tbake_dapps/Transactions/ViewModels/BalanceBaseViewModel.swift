// Copyright SIX DAY LLC. All rights reserved.

import Foundation
import UIKit
import BigInt

protocol BalanceBaseViewModel {
    var currencyAmount: String? { get }
    var amountFull: String { get }
    var amountShort: String { get }
    var symbol: String { get }

    var value: BigInt { get }
}
