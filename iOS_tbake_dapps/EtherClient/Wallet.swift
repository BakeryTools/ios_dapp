// Copyright SIX DAY LLC. All rights reserved.

import Foundation

enum WalletType: Equatable {
    case real(TBakeWallet.Address)
    case watch(TBakeWallet.Address)
}

struct Wallet: Equatable {
    let type: WalletType

    var address: TBakeWallet.Address {
        switch type {
        case .real(let account):
            return account
        case .watch(let address):
            return address
        }
    }

    var allowBackup: Bool {
        switch type {
        case .real:
            return true
        case .watch:
            return false
        }
    }
}
