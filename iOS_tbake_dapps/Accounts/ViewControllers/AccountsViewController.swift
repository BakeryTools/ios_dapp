// Copyright © 2018 Stormbird PTE. LTD.

import UIKit
import PromiseKit

protocol AccountsViewControllerDelegate: class {
    func didSelectAccount(account: Wallet, in viewController: AccountsViewController)
    func didDeleteAccount(account: Wallet, in viewController: AccountsViewController)
    func didSelectInfoForAccount(account: Wallet, sender: UIView, in viewController: AccountsViewController)
}

class AccountsViewController: UIViewController {
    private let roundedBackground = RoundedBackground()
    private let tableView = UITableView(frame: .zero, style: .plain)
    private var viewModel: AccountsViewModel
    private var balances: [AlphaWallet.Address: Balance?] = [:]
    private let config: Config
    private let keystore: Keystore
    private let balanceCoordinator: GetNativeCryptoCurrencyBalanceCoordinator
    weak var delegate: AccountsViewControllerDelegate?
    private let backgroundImage = UIImageView()
    var allowsAccountDeletion: Bool = false
    var hasWallets: Bool {
        return !keystore.wallets.isEmpty
    }

    init(config: Config, keystore: Keystore, balanceCoordinator: GetNativeCryptoCurrencyBalanceCoordinator, viewModel: AccountsViewModel) {
        self.config = config
        self.keystore = keystore
        self.balanceCoordinator = balanceCoordinator
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)

        self.backgroundImage.contentMode = .scaleAspectFill
        self.backgroundImage.translatesAutoresizingMaskIntoConstraints = false
        self.roundedBackground.addSubview(self.backgroundImage)
        
        view.backgroundColor = Colors.appBackground
        roundedBackground.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(roundedBackground)

        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .singleLine
        tableView.backgroundColor = Colors.backgroundClear
        tableView.tableFooterView = UIView()
        tableView.register(AccountViewCell.self)
        tableView.register(WalletSummaryTableViewCell.self)
        roundedBackground.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: roundedBackground.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: roundedBackground.trailingAnchor),
            tableView.topAnchor.constraint(equalTo: roundedBackground.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            self.backgroundImage.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            self.backgroundImage.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            self.backgroundImage.topAnchor.constraint(equalTo: view.topAnchor),
            self.backgroundImage.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
        ] + roundedBackground.createConstraintsWithContainer(view: view))
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        print("AccountsViewController")
        self.backgroundImage.image = UIImage(named: "background_img")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        configure(viewModel: .init(keystore: keystore, config: config, configuration: viewModel.configuration))
        refreshWalletBalances()
    }

    func configure(viewModel: AccountsViewModel) {
        self.viewModel = viewModel
        title = viewModel.title
        tableView.reloadData()
    }

    private func confirmDelete(account: Wallet) {
        confirm(
            title: R.string.localizable.accountsConfirmDeleteTitle(),
            message: R.string.localizable.accountsConfirmDeleteMessage(),
            okTitle: R.string.localizable.accountsConfirmDeleteOkTitle(),
            okStyle: .destructive
        ) { [weak self] result in
            guard let strongSelf = self else { return }
            switch result {
            case .success:
                strongSelf.delete(account: account)
            case .failure: break
            }
        }
    }

    private func delete(account: Wallet) {
        navigationController?.displayLoading(text: R.string.localizable.deleting())
        let result = keystore.delete(wallet: account)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            guard let strongSelf = self else { return }

            strongSelf.navigationController?.hideLoading()

            switch result {
            case .success:
                strongSelf.configure(viewModel: .init(keystore: strongSelf.keystore, config: strongSelf.config, configuration: strongSelf.viewModel.configuration))
                strongSelf.delegate?.didDeleteAccount(account: account, in: strongSelf)
            case .failure(let error):
                strongSelf.displayError(error: error)
            }
        }
    }

    private func refreshWalletBalances() {
        let group = DispatchGroup()

        for address in viewModel.addresses {
            group.enter()

            balanceCoordinator.getBalance(for: address) { [weak self] result in
                self?.balances[address] = result.value
                group.leave()
            }
        }

        group.notify(queue: .main) { [weak self] in
            self?.tableView.reloadData()
        }
    }

    private func getAccountViewModels(for path: IndexPath) -> AccountViewModel? {
        guard let account = viewModel.account(for: path) else { return nil }
        let walletName = viewModel.walletName(forAccount: account)
        let balance = self.balances[account.address].flatMap { $0 }
        return AccountViewModel(wallet: account, current: keystore.currentWallet, walletBalance: balance, server: balanceCoordinator.server, walletName: walletName)
    }

    required init?(coder aDecoder: NSCoder) {
        return nil
    }
}

extension AccountsViewController: UITableViewDataSource {

    public func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfItems(section: section)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch viewModel.sections[indexPath.section] {
        case .hdWallet, .keystoreWallet, .watchedWallet:
            let cell: AccountViewCell = tableView.dequeueReusableCell(for: indexPath)
            guard var cellViewModel = getAccountViewModels(for: indexPath) else {
                //NOTE: this should never happen here
                return UITableViewCell()
            }
            cell.configure(viewModel: cellViewModel)
            cell.account = cellViewModel.wallet

            let gesture = UILongPressGestureRecognizer(target: self, action: #selector(didLongPress))
            gesture.minimumPressDuration = 0.6
            cell.addGestureRecognizer(gesture)

            let address = cellViewModel.address
            ENSReverseLookupCoordinator(server: .forResolvingEns).getENSNameFromResolver(forAddress: address) { result in
                guard let ensName = result.value else { return }
                //Cell might have been reused. Check
                guard let cellAddress = cell.viewModel?.address, cellAddress.sameContract(as: address) else { return }
                cellViewModel.ensName = ensName
                cell.configure(viewModel: cellViewModel)
            }

            return cell
        case .summary:
            let cell: WalletSummaryTableViewCell = tableView.dequeueReusableCell(for: indexPath)
            cell.configure(viewModel: .init(walletBalance: nil, server: balanceCoordinator.server))

            return cell
        }
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        guard allowsAccountDeletion else { return false }
        return viewModel.canEditCell(indexPath: indexPath)
    }

    @objc private func didLongPress(_ recognizer: UILongPressGestureRecognizer) {
        guard let cell = recognizer.view as? AccountViewCell, let account = cell.account, recognizer.state == .began else { return }

        delegate?.didSelectInfoForAccount(account: account, sender: cell, in: self)
    }
}

extension AccountsViewController: UITableViewDelegate {

    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let value = viewModel.shouldHideHeader(in: section)
        let headerView = AccountViewTableSectionHeader()
        headerView.configure(type: value.section, shouldHide: value.shouldHide)

        return headerView
    }

    //Hide the footer
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        .zero
    }
    

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {

        let copyAction = UIContextualAction(style: .normal, title: R.string.localizable.copyAddress()) { _, _, complete in
            guard let account = self.viewModel.account(for: indexPath) else { return }
            UIPasteboard.general.string = account.address.eip55String
            complete(true)
        }

        copyAction.image = R.image.copy()?.withRenderingMode(.alwaysTemplate)
        copyAction.backgroundColor = R.color.azure()

        let deleteAction = UIContextualAction(style: .normal, title: R.string.localizable.accountsConfirmDeleteAction()) { _, _, complete in
            guard let account = self.viewModel.account(for: indexPath) else { return }
            self.confirmDelete(account: account)

            complete(true)
        }

        deleteAction.image = R.image.close()?.withRenderingMode(.alwaysTemplate)
        deleteAction.backgroundColor = R.color.danger()

        let configuration = UISwipeActionsConfiguration(actions: [copyAction, deleteAction])
        configuration.performsFirstActionWithFullSwipe = true

        return configuration
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        guard let account = viewModel.account(for: indexPath) else { return }

        delegate?.didSelectAccount(account: account, in: self)
    }
}
