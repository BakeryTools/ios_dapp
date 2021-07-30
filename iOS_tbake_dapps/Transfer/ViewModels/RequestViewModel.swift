// Copyright © 2018 Stormbird PTE. LTD.

import Foundation
import UIKit

struct RequestViewModel {
	private let account: Wallet

	init(account: Wallet) {
		self.account = account
	}

	var myAddressText: String {
		return account.address.eip55String
	}

	var myAddress: TBakeWallet.Address {
		return account.address
	}

	var copyWalletText: String {
		return R.string.localizable.requestCopyWalletButtonTitle()
	}

	var addressCopiedText: String {
		return R.string.localizable.requestAddressCopiedTitle()
	}

	var backgroundColor: UIColor {
		return Colors.backgroundClear
	}

	var addressLabelColor: UIColor {
        return Colors.black
	}

	var copyButtonsFont: UIFont {
		return Screen.TokenCard.Font.blockChainName
	}

	var labelColor: UIColor? {
        return Screen.TokenCard.Color.title
	}

	var addressFont: UIFont {
        return Screen.TokenCard.Font.blockChainName
	}

	var addressBackgroundColor: UIColor {
		return UIColor(red: 237, green: 237, blue: 237)
	}

	var instructionFont: UIFont {
        return Screen.TokenCard.Font.subtitle
	}

	var instructionText: String {
		return R.string.localizable.aWalletAddressScanInstructions()
	}
}
