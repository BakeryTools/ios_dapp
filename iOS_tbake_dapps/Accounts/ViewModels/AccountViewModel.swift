// Copyright SIX DAY LLC. All rights reserved.

import Foundation
import UIKit

struct AccountViewModel {
    let wallet: Wallet
    let current: Wallet?
    let walletName: String?
    var ensName: String?
    let icon: Subscribable<BlockiesImage> = Subscribable<BlockiesImage>(nil)
    
    init(wallet: Wallet, current: Wallet?, walletName: String?) {
        self.wallet = wallet
        self.current = current
        self.ensName = nil
        self.walletName = walletName

        AccountViewModel.resolveBlockie(for: self, size: 8, scale: 5)
    }

    var showWatchIcon: Bool {
        return wallet.type == .watch(wallet.address)
    }

    var address: TBakeWallet.Address {
        return wallet.address
    }

    var accessoryType: UITableViewCell.AccessoryType {
        return isSelected ? .checkmark : .disclosureIndicator
    }

    var isSelected: Bool {
        return wallet == current
    }

    var backgroundColor: UIColor {
        return Colors.backgroundClear
    }

    func apprecation24hourAttributedString(for balance: WalletBalance?) -> NSAttributedString {
        let style = NSMutableParagraphStyle()
        style.alignment = .right

        return .init(string: balance?.valuePercentageChangeValue ?? "-", attributes: [
            .font: Fonts.regular(size: 20),
            .foregroundColor: balance?.valuePercentageChangeColor ?? Colors.red, //Danial
            .paragraphStyle: style
        ])
    }
    
    func balanceAttributedString(for value: String?) -> NSAttributedString {
        return .init(string: value ?? "--", attributes: [
            .font: Screen.TokenCard.Font.title,
            .foregroundColor: Screen.TokenCard.Color.title,
        ])
    }

    var addressesAttrinutedString: NSAttributedString {
        return .init(string: addresses, attributes: [
            .font: Screen.TokenCard.Font.smallText,
            .foregroundColor: Screen.TokenCard.Color.grayLabel
        ])
    }

    private var addresses: String {
        if let walletName = walletName {
            return "\(walletName) | \(wallet.address.truncateMiddle)"
        } else if let ensName = ensName {
            return "\(ensName) | \(wallet.address.truncateMiddle)"
        } else {
            return wallet.address.eip55String
        }
    }
}

extension AccountViewModel {
    //Because struct can't capture self in closure we using static func to resolve blockie
    static func resolveBlockie(for viewModel: AccountViewModel, size: Int = 8, scale: Int = 3) {
        let generator = BlockiesGenerator()
        generator.promise(address: viewModel.address, size: size, scale: scale).done { image in
            viewModel.icon.value = image
        }.catch { _ in
            viewModel.icon.value = nil
        }
    }
}

