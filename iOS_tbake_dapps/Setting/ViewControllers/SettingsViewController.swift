// Copyright © 2018 Stormbird PTE. LTD.

import UIKit
import PromiseKit
import LocalAuthentication

protocol SettingsViewControllerDelegate: AnyObject, CanOpenURL {
    func settingsViewControllerAdvancedSettingsSelected(in controller: SettingsViewController)
    func settingsViewControllerChangeWalletSelected(in controller: SettingsViewController)
    func settingsViewControllerMyWalletAddressSelected(in controller: SettingsViewController)
    func settingsViewControllerShowSeedPhraseSelected(in controller: SettingsViewController)
    func settingsViewControllerWalletConnectSelected(in controller: SettingsViewController)
    func settingsViewControllerNameWalletSelected(in controller: SettingsViewController)
    func settingsViewControllerActiveNetworksSelected(in controller: SettingsViewController)
    func settingsViewControllerHelpSelected(in controller: SettingsViewController)
}

class SettingsViewController: UIViewController {
    private let lock = Lock()
    private var config: Config
    private let keystore: Keystore
    private let account: Wallet
    private let analyticsCoordinator: AnalyticsCoordinator
    private let backgroundImage = UIImageView()
    private let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.tableFooterView = UIView.tableFooterToRemoveEmptyCellSeparators()
        tableView.registerHeaderFooterView(SettingViewHeader.self)
        tableView.register(SettingTableViewCell.self)
        tableView.register(SwitchTableViewCell.self)
        tableView.estimatedRowHeight = UITableView.automaticDimension
        tableView.estimatedSectionHeaderHeight = UITableView.automaticDimension
        tableView.separatorStyle = .singleLine
        tableView.backgroundColor = Colors.backgroundClear

        return tableView
    }()
    private lazy var viewModel: SettingsViewModel = SettingsViewModel(account: account, keystore: keystore)

    weak var delegate: SettingsViewControllerDelegate?

    init(config: Config, keystore: Keystore, account: Wallet, analyticsCoordinator: AnalyticsCoordinator) {
        self.config = config
        self.keystore = keystore
        self.account = account
        self.analyticsCoordinator = analyticsCoordinator
        super.init(nibName: nil, bundle: nil)

        self.backgroundImage.contentMode = .scaleAspectFill
        self.backgroundImage.translatesAutoresizingMaskIntoConstraints = false
        
        self.tableView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.backgroundImage)
        self.view.addSubview(self.tableView)
        
        NSLayoutConstraint.activate([
            self.backgroundImage.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            self.backgroundImage.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            self.backgroundImage.topAnchor.constraint(equalTo: view.topAnchor),
            self.backgroundImage.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            self.tableView.topAnchor.constraint(equalTo: view.topAnchor),
            self.tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            self.tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            self.tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        tableView.dataSource = self
        tableView.delegate = self
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = R.string.localizable.aSettingsNavigationTitle()
        navigationItem.largeTitleDisplayMode = .never
        
        view.backgroundColor = Colors.appBackground
        self.backgroundImage.image = UIImage(named: "background_img")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        reflectCurrentWalletSecurityLevel()
    }

    private func hidePromptBackupWalletView() {
        tableView.tableHeaderView = nil
    }

    private func reflectCurrentWalletSecurityLevel() {
        tableView.reloadData()
    }

    private func setPasscode(completion: ((Bool) -> Void)? = .none) {
        guard let navigationController = navigationController else { return }
        let viewModel = LockCreatePasscodeViewModel()
        let lock = LockCreatePasscodeCoordinator(navigationController: navigationController, model: viewModel)
        lock.start()
        lock.lockViewController.willFinishWithResult = { result in
            completion?(result)
            lock.stop()
        }
    }

    private func configureChangeWalletCellWithResolvedENS(_ row: SettingsWalletRow, cell: SettingTableViewCell) {
        cell.configure(viewModel: .init(
            titleText: row.title,
            subTitleText: viewModel.addressReplacedWithENSOrWalletName(),
            icon: row.icon)
        )

        firstly {
            GetWalletNameCoordinator(config: config).getName(forAddress: account.address)
        }.done { [weak self] name in
            guard let strongSelf = self else { return }
            //TODO check if still correct cell, since this is async
            let viewModel: SettingTableViewCellViewModel = .init(
                    titleText: row.title,
                    subTitleText: strongSelf.viewModel.addressReplacedWithENSOrWalletName(name),
                    icon: row.icon
            )
            cell.configure(viewModel: viewModel)
        }.cauterize()
    }

    required init?(coder aDecoder: NSCoder) {
        return nil
    }
}

extension SettingsViewController: CanOpenURL {

    func didPressViewContractWebPage(forContract contract: TBakeWallet.Address, server: RPCServer, in viewController: UIViewController) {
        delegate?.didPressViewContractWebPage(forContract: contract, server: server, in: viewController)
    }

    func didPressViewContractWebPage(_ url: URL, in viewController: UIViewController) {
        delegate?.didPressViewContractWebPage(url, in: viewController)
    }

    func didPressOpenWebPage(_ url: URL, in viewController: UIViewController) {
        delegate?.didPressOpenWebPage(url, in: viewController)
    }
}

extension SettingsViewController: SwitchTableViewCellDelegate {

    func cell(_ cell: SwitchTableViewCell, switchStateChanged isOn: Bool) {
        guard let indexPath = cell.indexPath else { return }

        switch viewModel.sections[indexPath.section] {
        case .system(let rows):
            switch rows[indexPath.row] {
            case .passcode:
                if isOn {
                    setPasscode { result in
                        cell.isOn = result
                    }
                } else {
                    lock.deletePasscode()
                }
            case .darkmode:
                UserDefaults.standard.set(isOn ? true : false, forKey: "darkMode")
                getKeyWindow()?.overrideUserInterfaceStyle = isOn ? .dark : .light
            case .notifications, .selectActiveNetworks, .advanced:
                break
            }
        case .community, .tokenStandard, .version, .wallet:
            break
        }
    }
}

extension SettingsViewController: UITableViewDataSource {

    public func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.numberOfSections()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfSections(in: section)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch viewModel.sections[indexPath.section] {
        case .system(let rows):
            let row = rows[indexPath.row]
            switch row {
            case .passcode:
                let cell: SwitchTableViewCell = tableView.dequeueReusableCell(for: indexPath)
                cell.configure(viewModel: .init(
                    titleText: viewModel.passcodeTitle,
                    icon: row.icon,
                    value: lock.isPasscodeSet)
                )
                cell.delegate = self

                return cell
            case .notifications, .selectActiveNetworks, .advanced:
                let cell: SettingTableViewCell = tableView.dequeueReusableCell(for: indexPath)
                cell.configure(viewModel: .init(settingsSystemRow: row))

                return cell
            case .darkmode:
                let cell: SwitchTableViewCell = tableView.dequeueReusableCell(for: indexPath)
                cell.configure(viewModel: .init(
                                titleText: row.title,
                                icon: row.icon,
                                value: UserDefaults.standard.bool(forKey: "darkMode"))
                )
                cell.delegate = self

                return cell
            }
        case .community:
            let cell: SettingTableViewCell = tableView.dequeueReusableCell(for: indexPath)
            cell.configure(viewModel: .init(titleText: R.string.localizable.settingsSocialMediaTitle(), icon: UIImage(systemName: "person.3.fill") ?? UIImage()))

            return cell
        case .wallet(let rows):
            let cell: SettingTableViewCell = tableView.dequeueReusableCell(for: indexPath)
            let row = rows[indexPath.row]
            switch row {
            case .changeWallet:
                configureChangeWalletCellWithResolvedENS(row, cell: cell)

                return cell
            case .showMyWallet, .showSeedPhrase, .walletConnect, .nameWallet:
                cell.configure(viewModel: .init(settingsWalletRow: row))

                return cell
            }
        case .tokenStandard, .version:
            return UITableViewCell()
        }
    }
}

extension SettingsViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return .zero
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView: SettingViewHeader = tableView.dequeueReusableHeaderFooterView()
        let section = viewModel.sections[section]
        let viewModel = SettingViewHeaderViewModel(section: section)
        headerView.configure(viewModel: viewModel)

        return headerView
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch viewModel.sections[indexPath.section] {
        case .wallet(let rows):
            switch rows[indexPath.row] {
            case .changeWallet:
                delegate?.settingsViewControllerChangeWalletSelected(in: self)
            case .showMyWallet:
                delegate?.settingsViewControllerMyWalletAddressSelected(in: self)
            case .showSeedPhrase:
                delegate?.settingsViewControllerShowSeedPhraseSelected(in: self)
            case .walletConnect:
                delegate?.settingsViewControllerWalletConnectSelected(in: self)
            case .nameWallet:
                delegate?.settingsViewControllerNameWalletSelected(in: self)
            }
        case .system(let rows):
            switch rows[indexPath.row] {
            case .advanced:
                delegate?.settingsViewControllerAdvancedSettingsSelected(in: self)
            case .notifications:
                break
            case .passcode:
                break
            case .selectActiveNetworks:
                delegate?.settingsViewControllerActiveNetworksSelected(in: self)
            case .darkmode:
                break
            }
        case .community:
            delegate?.settingsViewControllerHelpSelected(in: self)
        case .tokenStandard:
            self.delegate?.didPressOpenWebPage(TokenScript.tokenScriptSite, in: self)
        case .version:
            break
        }
    }
}
