// Copyright SIX DAY LLC. All rights reserved.

import Foundation
import UIKit

struct SettingsViewModel {
    private let account: Wallet

    func addressReplacedWithENSOrWalletName(_ ensOrWalletName: String? = nil) -> String {
        if let ensOrWalletName = ensOrWalletName {
            return "\(ensOrWalletName) | \(account.address.truncateMiddle)"
        } else {
            return account.address.eip55String
        }
    }

    var passcodeTitle: String {
        switch BiometryAuthenticationType.current {
        case .faceID, .touchID:
            return R.string.localizable.settingsBiometricsEnabledLabelTitle(BiometryAuthenticationType.current.title)
        case .none:
            return R.string.localizable.settingsBiometricsDisabledLabelTitle()
        }
    }

    var localeTitle: String {
        return R.string.localizable.settingsLanguageButtonTitle()
    }

    let sections: [SettingsSection]

    init(account: Wallet, keystore: Keystore) {
        self.account = account
        let walletRows: [SettingsWalletRow]

        if account.allowBackup {
            if keystore.isHdWallet(wallet: account) {
                walletRows = [.changeWallet, .showSeedPhrase]
            } else {
                walletRows = [.changeWallet]
            }
        } else {
            walletRows = [.changeWallet]
        }

        sections = [
            .wallet(rows: walletRows),
            .community,
            .system(rows: [.passcode, .darkmode])
        ]
    }

    func numberOfSections() -> Int {
        return sections.count
    }

    func numberOfSections(in section: Int) -> Int {
        switch sections[section] {
        case .wallet(let rows):
            return rows.count
        case .community:
            return 1
        case .system(let rows):
            return rows.count
        case .version, .tokenStandard:
            return 0
        }
    }
}

enum SettingsWalletRow: CaseIterable {
    case showMyWallet
    case changeWallet
    case showSeedPhrase
    case walletConnect
    case nameWallet

    var title: String {
        switch self {
        case .showMyWallet:
            return R.string.localizable.settingsShowMyWalletTitle()
        case .changeWallet:
            return R.string.localizable.settingsChangeWalletTitle()
        case .showSeedPhrase:
            return R.string.localizable.settingsShowSeedPhraseButtonTitle()
        case .walletConnect:
            return R.string.localizable.settingsWalletConnectButtonTitle()
        case .nameWallet:
            return R.string.localizable.settingsWalletRename()
        }
    }

    var icon: UIImage {
        switch self {
        case .showMyWallet:
            return R.image.walletAddress()!
        case .changeWallet:
            return UIImage(systemName: "wallet.pass.fill") ?? UIImage()
        case .showSeedPhrase:
            return UIImage(systemName: "key.fill") ?? UIImage()
        case .walletConnect:
            return R.image.iconsSettingsWalletConnect()!
        case .nameWallet:
            return R.image.iconsSettingsDisplayedEns()!
        }
    }
}

enum SettingsSystemRow: CaseIterable {
    case notifications
    case passcode
    case darkmode
    case selectActiveNetworks
    case advanced

    var title: String {
        switch self {
        case .notifications:
            return R.string.localizable.settingsNotificationsTitle()
        case .passcode:
            return R.string.localizable.settingsPasscodeTitle()
        case .selectActiveNetworks:
            return R.string.localizable.settingsSelectActiveNetworksTitle()
        case .advanced:
            return R.string.localizable.advanced()
        case .darkmode:
            return R.string.localizable.settingsDarkmodeTitle()
        }
    }

    var passcodeIcon: UIImage {
        switch BiometryAuthenticationType.current {
        case .faceID:
            return UIImage(systemName: "faceid") ?? UIImage()
        case .touchID:
            return UIImage(systemName: "touchid") ?? UIImage()
        case .none:
            return UIImage(systemName: "lock.circle.fill") ?? UIImage()
        }
    }
    
    var icon: UIImage {
        switch self {
        case .notifications:
            return R.image.notificationsCircle()!
        case .passcode:
            return passcodeIcon
        case .selectActiveNetworks:
            return R.image.networksCircle()!
        case .advanced:
            return R.image.developerMode()!
        case .darkmode:
            return UIImage(systemName: "moon.circle.fill") ?? UIImage()
        }
    }
}

enum SettingsSection {
    case wallet(rows: [SettingsWalletRow])
    case system(rows: [SettingsSystemRow])
    case community
    case version(value: String)
    case tokenStandard(value: String)

    var title: String {
        switch self {
        case .wallet:
            return R.string.localizable.settingsSectionWalletTitle()
        case .community:
            return R.string.localizable.settingsSectionCommunityTitle()
        case .system:
            return R.string.localizable.settingsSectionSystemTitle()
        case .version:
            return R.string.localizable.settingsVersionLabelTitle()
        case .tokenStandard:
            return R.string.localizable.settingsTokenScriptStandardTitle()
        }
    }

    var numberOfRows: Int {
        switch self {
        case .wallet(let rows):
            return rows.count
        case .community:
            return 1
        case .system(let rows):
            return rows.count
        case .version, .tokenStandard:
            return 0
        }
    }
}
