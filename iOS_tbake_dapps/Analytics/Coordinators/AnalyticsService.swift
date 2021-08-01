//
//  BartercardAnalytics.swift
//  AlphaWallet
//
//  Created by Vladyslav Shepitko on 06.11.2020.
//

import UIKit
import AppTrackingTransparency

protocol AnalyticsServiceType: AnalyticsCoordinator {
    func applicationDidBecomeActive()
    func application(continue userActivity: NSUserActivity)
    func application(open url: URL, sourceApplication: String?, annotation: Any)
    func application(open url: URL, options: [UIApplication.OpenURLOptionsKey: Any])
    func application(didReceiveRemoteNotification userInfo: [AnyHashable: Any])

    func add(pushDeviceToken token: Data)
}

class AnalyticsService: NSObject, AnalyticsServiceType {
    private var mixpanelService: MixpanelCoordinator?

    private static var isTestFlight: Bool {
        Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt"
    }

    override init() {
        super.init()
        
        if #available(iOS 14, *) {
            ATTrackingManager.requestTrackingAuthorization { status in
                if status == .authorized {
                    if Constants.Credentials.analyticsKey.nonEmpty && !Self.isTestFlight {
                        self.mixpanelService = MixpanelCoordinator(withKey: Constants.Credentials.analyticsKey)
                    }
                }
            }
        } else {
            if Constants.Credentials.analyticsKey.nonEmpty && !Self.isTestFlight {
                self.mixpanelService = MixpanelCoordinator(withKey: Constants.Credentials.analyticsKey)
            }
        }
    }

    func add(pushDeviceToken token: Data) {
        if #available(iOS 14, *) {
            ATTrackingManager.requestTrackingAuthorization { status in
                if status == .authorized {
                    self.mixpanelService?.add(pushDeviceToken: token)
                }
            }
        } else {
            self.mixpanelService?.add(pushDeviceToken: token)
        }
    }

    func applicationDidBecomeActive() {

    }

    func application(continue userActivity: NSUserActivity) {

    }

    func application(open url: URL, sourceApplication: String?, annotation: Any) {

    }

    func application(open url: URL, options: [UIApplication.OpenURLOptionsKey: Any]) {

    }

    func application(didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {

    }

    func log(navigation: AnalyticsNavigation, properties: [String: AnalyticsEventPropertyValue]?) {
        if #available(iOS 14, *) {
            ATTrackingManager.requestTrackingAuthorization { status in
                if status == .authorized {
                    self.mixpanelService?.log(navigation: navigation, properties: properties)
                }
            }
        } else {
            self.mixpanelService?.log(navigation: navigation, properties: properties)
        }
    }

    func log(action: AnalyticsAction, properties: [String: AnalyticsEventPropertyValue]?) {
        if #available(iOS 14, *) {
            ATTrackingManager.requestTrackingAuthorization { status in
                if status == .authorized {
                    self.mixpanelService?.log(action: action, properties: properties)
                }
            }
        } else {
            self.mixpanelService?.log(action: action, properties: properties)
        }
    }

    func setUser(property: AnalyticsUserProperty, value: AnalyticsEventPropertyValue) {
        if #available(iOS 14, *) {
            ATTrackingManager.requestTrackingAuthorization { status in
                if status == .authorized {
                    self.mixpanelService?.setUser(property: property, value: value)
                }
            }
        } else {
            self.mixpanelService?.setUser(property: property, value: value)
        }
    }

    func incrementUser(property: AnalyticsUserProperty, by value: Int) {
        if #available(iOS 14, *) {
            ATTrackingManager.requestTrackingAuthorization { status in
                if status == .authorized {
                    self.mixpanelService?.incrementUser(property: property, by: value)
                }
            }
        } else {
            self.mixpanelService?.incrementUser(property: property, by: value)
        }
    }

    func incrementUser(property: AnalyticsUserProperty, by value: Double) {
        if #available(iOS 14, *) {
            ATTrackingManager.requestTrackingAuthorization { status in
                if status == .authorized {
                    self.mixpanelService?.incrementUser(property: property, by: value)
                }
            }
        } else {
            self.mixpanelService?.incrementUser(property: property, by: value)
        }
    }
}
