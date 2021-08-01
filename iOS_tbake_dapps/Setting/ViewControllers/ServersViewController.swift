// Copyright © 2018 Stormbird PTE. LTD.

import UIKit

protocol ServersViewControllerDelegate: AnyObject {
    func didSelectServer(server: RPCServerOrAuto, in viewController: ServersViewController)
}

class ServersViewController: UIViewController {
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .singleLine
        tableView.backgroundColor = GroupedTable.Color.background
        tableView.tableFooterView = UIView.tableFooterToRemoveEmptyCellSeparators()
        tableView.register(ServerViewCell.self)

        return tableView
    }()
    private var viewModel: ServersViewModel
    private let backgroundImage = UIImageView()

    weak var delegate: ServersViewControllerDelegate?

    init(viewModel: ServersViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        
        self.backgroundImage.contentMode = .scaleAspectFill
        self.backgroundImage.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.backgroundImage)

        view.backgroundColor = GroupedTable.Color.background
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            self.backgroundImage.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            self.backgroundImage.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            self.backgroundImage.topAnchor.constraint(equalTo: view.topAnchor),
            self.backgroundImage.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            tableView.anchorsConstraint(to: view)
        ])
    } 

    override func viewDidLoad() {
        super.viewDidLoad()
        print("ServersViewController")
        configure(viewModel: viewModel)
    }

    func configure(viewModel: ServersViewModel) {
        self.viewModel = viewModel
        navigationItem.title = viewModel.title
    }

    required init?(coder aDecoder: NSCoder) {
        return nil
    }
}

extension ServersViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.servers.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: ServerViewCell = tableView.dequeueReusableCell(for: indexPath)
        let server = viewModel.server(for: indexPath)
        let cellViewModel = ServerViewModel(server: server, selected: viewModel.isServerSelected(server))
        cell.configure(viewModel: cellViewModel)

        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let server = viewModel.server(for: indexPath)
        delegate?.didSelectServer(server: server, in: self)
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        .leastNonzeroMagnitude
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard viewModel.displayWarningFooter else {
            return nil
        }

        let footer = UIView()
        let label = UILabel()
        label.numberOfLines = 0
        label.textColor = viewModel.descriptionColor
        label.text = viewModel.descriptionText
        label.translatesAutoresizingMaskIntoConstraints = false
        footer.addSubview(label)
        NSLayoutConstraint.activate([
            label.anchorsConstraint(to: footer, edgeInsets: .init(top: 7, left: 20, bottom: 0, right: 20))
        ])

        return footer
    }
}
