//
//  SupportViewController.swift
//  AlphaWallet
//
//  Created by Vladyslav Shepitko on 04.06.2020.
//

import UIKit

protocol SupportViewControllerDelegate: AnyObject, CanOpenURL {

}

class SupportViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    
    private let analyticsCoordinator: AnalyticsCoordinator
    private lazy var viewModel: SupportViewModel = SupportViewModel()

    weak var delegate: SupportViewControllerDelegate?

    init(analyticsCoordinator: AnalyticsCoordinator) {
        self.analyticsCoordinator = analyticsCoordinator
        super.init(nibName: nil, bundle: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        print("SupportViewController")
        title = viewModel.title
        self.setupTableView()
    }

    required init?(coder aDecoder: NSCoder) {
        return nil
    }
    
    private func setupTableView() {
        self.tableView.tableFooterView = UIView.tableFooterToRemoveEmptyCellSeparators()
        self.tableView.register(SettingTableViewCell.self)
        self.tableView.separatorStyle = .singleLine
        self.tableView.dataSource = self
        self.tableView.delegate = self
    }
}

extension SupportViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: SettingTableViewCell = tableView.dequeueReusableCell(for: indexPath)
        cell.configure(viewModel: viewModel.cellViewModel(indexPath: indexPath))

        return cell
    }
}


extension SupportViewController: CanOpenURL {

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

extension SupportViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    //Hide the header
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        .leastNormalMagnitude
    }
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        nil
    }

    //Hide the footer
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        .leastNormalMagnitude
    }
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        nil
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch viewModel.rows[indexPath.row] {
        case .website:
            openURL(.website)
        case .telegramAnnouncement:
            openURL(.telegramAnnouncement)
        case .telegramGroup:
            openURL(.telegramGroup)
        case .twitter:
            openURL(.twitter)
        case .medium:
            openURL(.medium)
        case .github:
            openURL(.github)
        }
    }

    private func openURL(_ provider: URLServiceProvider) {
        if let localURL = provider.localURL, UIApplication.shared.canOpenURL(localURL) {
            UIApplication.shared.open(localURL, options: [:], completionHandler: .none)
        } else {
            delegate?.didPressOpenWebPage(provider.remoteURL, in: self)
        }
    }
}

// MARK: Analytics
extension SupportViewController {
    private func logAccessFaq() {
        analyticsCoordinator.log(navigation: Analytics.Navigation.faq)
    }

    private func logAccessTelegramPublic() {
        analyticsCoordinator.log(navigation: Analytics.Navigation.telegramPublic)
    }

    private func logAccessTelegramCustomerSupport() {
        analyticsCoordinator.log(navigation: Analytics.Navigation.telegramCustomerSupport)
    }

    private func logAccessTwitter() {
        analyticsCoordinator.log(navigation: Analytics.Navigation.twitter)
    }

    private func logAccessReddit() {
        analyticsCoordinator.log(navigation: Analytics.Navigation.reddit)
    }

    private func logAccessFacebook() {
        analyticsCoordinator.log(navigation: Analytics.Navigation.facebook)
    }
}
