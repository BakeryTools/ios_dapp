// Copyright © 2019 Stormbird PTE. LTD.

import UIKit

protocol EnabledServersViewControllerDelegate: AnyObject {
    func didSelectServers(servers: [RPCServer], in viewController: EnabledServersViewController)
    func notifyRemoveCustomChainQueued(in viewController: EnabledServersViewController)
}

class EnabledServersViewController: UIViewController {
    enum Section {
//        case testnet
        case mainnet
    }

    private let roundedBackground = RoundedBackground()
    private let headers = EnableServersHeaderView()
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.separatorStyle = .singleLine
        tableView.backgroundColor = GroupedTable.Color.background
        tableView.tableFooterView = UIView.tableFooterToRemoveEmptyCellSeparators()
        tableView.register(ServerViewCell.self)
        tableView.dataSource = self

        return tableView
    }()
    private let restartQueue: RestartTaskQueue
    private let sections: [Section] = [.mainnet]
    private var serversSelectedInPreviousMode: [RPCServer]?
    private var sectionIndices: IndexSet {
        IndexSet(integersIn: Range(uncheckedBounds: (lower: 0, sections.count)))
    }

    var viewModel: EnabledServersViewModel
    weak var delegate: EnabledServersViewControllerDelegate?

    init(viewModel: EnabledServersViewModel, restartQueue: RestartTaskQueue) {
        self.viewModel = viewModel
        self.restartQueue = restartQueue
        super.init(nibName: nil, bundle: nil)

        view.backgroundColor = GroupedTable.Color.background

        roundedBackground.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(roundedBackground)
        roundedBackground.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: roundedBackground.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: roundedBackground.trailingAnchor),
            tableView.topAnchor.constraint(equalTo: roundedBackground.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ] + roundedBackground.createConstraintsWithContainer(view: view))
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configure(viewModel: viewModel)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isMovingFromParent {
            done()
        } else {
            //no-op
        }
    }

    func configure(viewModel: EnabledServersViewModel) {
        self.viewModel = viewModel
        title = viewModel.title
    }

    required init?(coder aDecoder: NSCoder) {
        return nil
    }

    @objc private func done() {
        delegate?.didSelectServers(servers: viewModel.selectedServers, in: self)
    }

    private func confirmDelete(server: RPCServer) {
        guard server.isCustom else { return }
        guard !viewModel.isServerSelected(server) else { return }
        //TODO make it possible to remove custom chains without restarting UI
        confirm(title: R.string.localizable.settingsEnabledNetworksDeleteTitle(), message: R.string.localizable.settingsEnabledNetworksDeleteMessage(), okTitle: R.string.localizable.delete(), okStyle: .destructive) { [weak self] result in
            guard let strongSelf = self else { return }
            switch result {
            case .success:
                strongSelf.markForDeletion(server: server)
            case .failure:
                break
            }
        }
    }

    private func markForDeletion(server: RPCServer) {
        guard let customRpc = server.customRpc else { return }
        restartQueue.add(.removeServer(customRpc))
        delegate?.notifyRemoveCustomChainQueued(in: self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        print("EnabledServersViewController")
    }
}

extension EnabledServersViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch sections[section] {
        case .mainnet:
            return viewModel.serverCount(forMode: .mainnet)
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView: EnableServersHeaderView
        switch sections[section] {
        case .mainnet:
            headerView = headers
            headerView.configure(mode: .mainnet, isEnabled: viewModel.mode == .mainnet)
        }
        headerView.delegate = self
        return headerView
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        50
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: ServerViewCell = tableView.dequeueReusableCell(for: indexPath)
        let server = viewModel.server(for: indexPath)
        let cellViewModel = ServerViewModel(server: server, selected: viewModel.isServerSelected(server))
        cell.configure(viewModel: cellViewModel)

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let server = viewModel.server(for: indexPath)
        let servers: [RPCServer]
        if viewModel.selectedServers.contains(server) {
            servers = viewModel.selectedServers - [server]
        } else {
            servers = viewModel.selectedServers + [server]
        }
        configure(viewModel: .init(servers: viewModel.servers, selectedServers: servers))
        tableView.reloadData()
        //Even if no servers is selected, we don't attempt to disable the back button here since calling code will take care of ignore the change server "request" when there are no servers selected. We don't want to disable the back button because users can't cancel the operation
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let server = viewModel.server(for: indexPath)
        guard server.isCustom else { return nil }
        guard !viewModel.isServerSelected(server) else { return nil }
        let deleteAction = UIContextualAction(style: .normal, title: R.string.localizable.delete()) { _, _, complete in
            self.confirmDelete(server: server)
            complete(true)
        }

        deleteAction.image = R.image.close()?.withRenderingMode(.alwaysTemplate)
        deleteAction.backgroundColor = R.color.danger()

        let configuration = UISwipeActionsConfiguration(actions: [deleteAction])
        configuration.performsFirstActionWithFullSwipe = true

        return configuration
    }
}

extension EnabledServersViewController: EnableServersHeaderViewDelegate {
    func toggledTo(_ newValue: Bool, headerView: EnableServersHeaderView) {
        switch (headerView.mode, newValue) {
        case (.mainnet, true), (.testnet, false):
            if let serversSelectedInPreviousMode = serversSelectedInPreviousMode {
                self.serversSelectedInPreviousMode = viewModel.selectedServers
                configure(viewModel: .init(servers: viewModel.servers, selectedServers: serversSelectedInPreviousMode))
            } else {
                serversSelectedInPreviousMode = viewModel.selectedServers
                configure(viewModel: .init(servers: viewModel.servers, selectedServers: Constants.defaultEnabledServers))
            }
            tableView.reloadData()
            tableView.reloadSections(sectionIndices, with: .automatic)
        case (.mainnet, false), (.testnet, true):
            let prompt = PromptViewController()
            prompt.configure(viewModel: .init(title: R.string.localizable.settingsEnabledNetworksPromptEnableTestnetTitle(), description: R.string.localizable.settingsEnabledNetworksPromptEnableTestnetDescription(), buttonTitle: R.string.localizable.settingsEnabledNetworksPromptEnableTestnetButtonTitle()))
            prompt.modalPresentationStyle = .overFullScreen
            prompt.modalTransitionStyle = .crossDissolve
            prompt.view.backgroundColor = UIColor.black.withAlphaComponent(0.6)
            prompt.delegate = self
            present(prompt, animated: true)
        }
    }
}

extension EnabledServersViewController: PromptViewControllerDelegate {
    func actionButtonTapped(inController controller: PromptViewController) {
        controller.dismiss(animated: true) {
            if let serversSelectedInPreviousMode = self.serversSelectedInPreviousMode {
                self.serversSelectedInPreviousMode = self.viewModel.selectedServers
                self.configure(viewModel: .init(servers: self.viewModel.servers, selectedServers: serversSelectedInPreviousMode))
            } else {
                self.serversSelectedInPreviousMode = self.viewModel.selectedServers
                self.configure(viewModel: .init(servers: self.viewModel.servers, selectedServers: Constants.defaultEnabledTestnetServers))
            }
            //Animation breaks section headers. No idea why. So don't animate
            self.tableView.reloadData()
        }
    }

    func controllerDismiss(_ controller: PromptViewController) {
        controller.dismiss(animated: true) {
            self.headers.configure(mode: .mainnet, isEnabled: true)
//            self.headers.testnet.configure(mode: .testnet, isEnabled: false)
        }
    }
}
