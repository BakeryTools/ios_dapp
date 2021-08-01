// Copyright SIX DAY LLC. All rights reserved.
import Foundation
import UIKit
import StoreKit

class HelpUsCoordinator: Coordinator {
    private let navigationController: UINavigationController
    private let appTracker: AppTracker
    private let viewModel = HelpUsViewModel()

    var coordinators: [Coordinator] = []

    init(
        navigationController: UINavigationController = UINavigationController(),
        appTracker: AppTracker = AppTracker()
    ) {
        self.navigationController = navigationController
        self.navigationController.modalPresentationStyle = .formSheet
        self.appTracker = appTracker
    }

    func start() {
        switch hideShakeNib() {
        case true:
            break
        default:
            DispatchQueue.main.async {
                self.presentShakeShakeNib()
            }
        }
    }

    func rateUs() {
        SKStoreReviewController.requestReview()
        appTracker.completedRating = true
    }
    
    private func presentShakeShakeNib() {
        let nib = ShakeShakeViewController(nibName: "ShakeShakeViewController", bundle: nil)
        nib.modalPresentationStyle = .overCurrentContext
        nib.modalTransitionStyle = .crossDissolve
        navigationController.present(nib, animated: true, completion: nil)
    }
}

