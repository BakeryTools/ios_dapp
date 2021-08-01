//
//  FeedbackGenerator.swift
//  AlphaWallet
//
//  Created by Vladyslav Shepitko on 11.11.2020.
//

import UIKit
import PromiseKit

enum NotificationFeedbackType {
    case success
    case warning
    case error

    var feedbackType: UINotificationFeedbackGenerator.FeedbackType {
        switch self {
        case .success:
            return .success
        case .warning:
            return .warning
        case .error:
            return .error
        }
    }
}

extension UINotificationFeedbackGenerator {

    static func show(feedbackType result: NotificationFeedbackType, completion: @escaping () -> Void = {}) {
        let feedbackGenerator = UINotificationFeedbackGenerator()
        feedbackGenerator.prepare()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            feedbackGenerator.notificationOccurred(result.feedbackType)
            completion()
        }
    }
    
    static func showFeedbackPromise<T>(value: T, feedbackType: NotificationFeedbackType) -> Promise<T> {
        return Promise { seal in
            UINotificationFeedbackGenerator.show(feedbackType: feedbackType) {
                seal.fulfill(value)
            }
        }
    }
}
