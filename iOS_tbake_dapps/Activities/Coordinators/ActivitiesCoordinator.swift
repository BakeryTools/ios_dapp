// Copyright © 2020 Stormbird PTE. LTD.

import UIKit

protocol ActivitiesCoordinatorDelegate: AnyObject {
    func didPressTransaction(transaction: TransactionInstance, in viewController: ActivitiesViewController)
    func didPressActivity(activity: Activity, in viewController: ActivitiesViewController)
}

class ActivitiesCoordinator: NSObject, Coordinator {
    private let analyticsCoordinator: AnalyticsCoordinator
    private let sessions: ServerDictionary<WalletSession>
    private let tokensStorages: ServerDictionary<TokensDataStore>
    private let assetDefinitionStore: AssetDefinitionStore

    private let activitiesService: ActivitiesServiceType
    weak var delegate: ActivitiesCoordinatorDelegate?

    private lazy var viewController: ActivitiesViewController = .init(viewModel: ActivitiesViewModel(), sessions: sessions)

    let navigationController: UINavigationController
    var coordinators: [Coordinator] = []
    private var subscriptionKey: Subscribable<ActivitiesViewModel>.SubscribableKey!

    init(
        analyticsCoordinator: AnalyticsCoordinator,
        sessions: ServerDictionary<WalletSession>,
        navigationController: UINavigationController,
        tokensStorages: ServerDictionary<TokensDataStore>,
        assetDefinitionStore: AssetDefinitionStore,
        activitiesService: ActivitiesServiceType
    ) {
        self.activitiesService = activitiesService
        self.analyticsCoordinator = analyticsCoordinator
        self.sessions = sessions
        self.navigationController = navigationController
        self.tokensStorages = tokensStorages
        self.assetDefinitionStore = assetDefinitionStore
        super.init()

        subscriptionKey = activitiesService.subscribableViewModel.subscribe { [weak self] viewModel in
            guard let self = self, let viewModel = viewModel else { return }
            self.viewController.configure(viewModel: viewModel)
        }
    }

    func start() {
        viewController.delegate = self
        viewController.navigationItem.largeTitleDisplayMode = .never
        viewController.hidesBottomBarWhenPushed = true
        self.navigationController.pushViewController(viewController, animated: true)
    }

    @objc func dismiss() {
        navigationController.dismiss(animated: true)
    }

    func stop() {
        activitiesService.stop()
    }
}

extension ActivitiesCoordinator: ActivitiesViewControllerDelegate {
    func didPressActivity(activity: Activity, in viewController: ActivitiesViewController) {
        delegate?.didPressActivity(activity: activity, in: viewController)
    }

    func didPressTransaction(transaction: TransactionInstance, in viewController: ActivitiesViewController) {
        delegate?.didPressTransaction(transaction: transaction, in: viewController)
    }
}
