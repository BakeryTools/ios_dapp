// Copyright © 2018 Stormbird PTE. LTD.

import UIKit

protocol AssetDefinitionsOverridesViewControllerDelegate: AnyObject {
    func didDelete(overrideFileForContract file: URL, in viewController: AssetDefinitionsOverridesViewController)
    func didTapShare(file: URL, in viewController: AssetDefinitionsOverridesViewController)
}

class AssetDefinitionsOverridesViewController: UIViewController {
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let fileExtension: String
    private var overriddenURLs: [URL] = []
    weak var delegate: AssetDefinitionsOverridesViewControllerDelegate?

    init(fileExtension: String) {
        self.fileExtension = fileExtension
        super.init(nibName: nil, bundle: nil)

        view.backgroundColor = GroupedTable.Color.background

        tableView.register(AssetDefinitionsOverridesViewCell.self)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .singleLine
        tableView.backgroundColor = GroupedTable.Color.background
        tableView.tableFooterView = UIView.tableFooterToRemoveEmptyCellSeparators()

        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.anchorsConstraint(to: view),
        ])
    }
    
    override func viewWillAppear(_ animated: Bool) {
        print("AssetDefinitionsOverridesViewController")
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(overriddenURLs urls: [URL]) {
        self.overriddenURLs = urls
        tableView.reloadData()
    }
}

extension AssetDefinitionsOverridesViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            delegate?.didDelete(overrideFileForContract: overriddenURLs[indexPath.row], in: self)
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate?.didTapShare(file: overriddenURLs[indexPath.row], in: self)
    }
}

extension AssetDefinitionsOverridesViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: AssetDefinitionsOverridesViewCell = tableView.dequeueReusableCell(for: indexPath) 
        cell.configure(viewModel: .init(url: overriddenURLs[indexPath.row], fileExtension: fileExtension))
        return cell
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return overriddenURLs.count
    }
}
