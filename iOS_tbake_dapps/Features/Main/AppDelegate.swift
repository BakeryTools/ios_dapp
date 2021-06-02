//
//  AppDelegate.swift
//  iOS_tbake_dapps
//
//  Created by Danial on 20/05/2021.
//

import UIKit
import IQKeyboardManagerSwift
import AppTrackingTransparency

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        //implements keyboard handling
        IQKeyboardManager.shared.enable = true
        IQKeyboardManager.shared.shouldResignOnTouchOutside = true
        
        // Shake to share report
//        let appName = Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String
//        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
//        let deviceVersion = UIDevice.current.systemVersion
//        let deviceModel = UIDevice.modelName
//        let mobileId = UIDevice.current.identifierForVendor?.uuidString
//
//        BugShaker.configure(to: ["danial@recomn.com"], subject: "Recommend App Bug Report / Feedback", body: """
//            <strong>App Version:</strong> \(appName ?? "") (v\(appVersion ?? ""))<br/>
//            <strong>iOS Version:</strong> \(deviceVersion)<br/>
//            <strong>Device Model:</strong> \(deviceModel)<br/>
//            <strong>Mobile ID:</strong> \(mobileId ?? "")<br/>
//            """
//        )
        
//        if #available(iOS 14, *) {
//            ATTrackingManager.requestTrackingAuthorization { status in
//                if status == .authorized {
//                    ApplicationDelegate.shared.application(application, didFinishLaunchingWithOptions: launchOptions)
//                }
//            }
//        } else {
//            ApplicationDelegate.shared.application(application, didFinishLaunchingWithOptions: launchOptions)
//        }
        
        // Register push notification
        PushNotificationsRegistration()
        UIApplication.shared.registerForRemoteNotifications()
        // set app delegate as notification center delegate
        // this is IMPORTANT for handling notification in background and foreground
        UNUserNotificationCenter.current().delegate = self
        
        //Determine environment
        #if DEBUG
            UserDefaults.standard.set("DEV", forKey: "ENVIRONMENT")
        #else
            UserDefaults.standard.set("PRD", forKey: "ENVIRONMENT")
        #endif
        
        return true
    }
    
    // MARK: UISceneSession Lifecycle
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    func handleNotification(notificationData: [String: Any]) {
     
    }
}

extension AppDelegate {
    // "content-available": 1 -> enter this state
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        #if DEBUG
        print("-->Remote Notification(background/foreground): \(#function)")
        #endif
        guard let userinfo = userInfo as? [String: Any] else {
            completionHandler(.failed)
            return
        }
        #if DEBUG
        print(userinfo)
        #endif
        // prevent remote notification called twice
        // https://stackoverflow.com/questions/20569201/remote-notification-method-called-twice
//        if application.applicationState == .background {
//            completionHandler(UIBackgroundFetchResult.noData)
//            return
//        }
        
        //get badge count
        guard let data = userinfo["custom"] as? [String: Any] else { return completionHandler(.failed) }
        guard let customData = data["a"] as? [String: Any] else { return completionHandler(.failed) }
        guard let notificationCount = customData["unread_notification_count"] as? Int else { return completionHandler(.failed) }
//        guard let isRefreshPage = customData["refresh_page"] as? Int else { return completionHandler(.failed) }
        
        // temporary not used
        switch UIApplication.shared.applicationState {
        case .active: // foreground click on notification
            //app is currently active, can update badges count here
//            UserPrefs.riwayatNeedRefresh.set(isRefreshPage)
            UserPrefs.notificationCount.set(notificationCount)
            break
        case .inactive: // foreground to background and click on notification
            //app is transitioning from background to foreground (user taps notification), do what you need when user taps here
//            UserPrefs.riwayatNeedRefresh.set(isRefreshPage)
            UserPrefs.notificationCount.set(notificationCount)
            break
        case .background:
            //app is in background, if content-available key of your notification is set to 1, poll to your backend to retrieve data and update your interface here
            UserPrefs.notificationCount.set(getNotificationBadge() + application.applicationIconBadgeNumber)
            break
        default:
            break
        }
        
        NotificationCenter.default.post(Notification(name: Notification.Name("didReceiveNotification")))
        NotificationCenter.default.post(Notification(name: Notification.Name("didReceiveLatestUpdateWebview")))
        
        completionHandler(.newData)
    }
       
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        #if DEBUG
        print("Failed to register: \(error)")
        #endif
    }
       
    func PushNotificationsRegistration() {
        UNUserNotificationCenter.current() // handles all notification-related activities in the app
            .requestAuthorization(options: [.alert, .sound, .badge]) {
                [weak self] granted, error in
                #if DEBUG
                print("Permission push notification granted: \(granted)")
                #endif
                guard granted else { return }
                guard let self = self else { return }
                self.getNotificationSettings()
        }
    }
       
    func getNotificationSettings() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            #if DEBUG
            print("Notification settings: \(settings)")
            #endif
            guard settings.authorizationStatus == .authorized else { return }
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }
}


// MARK: - Extension UNUserNotificationCenterDelegate (User Notifications)
extension AppDelegate: UNUserNotificationCenterDelegate {
    
    // called when user interacts with notification
    // when app is not killed and quit within 10 mins, app is in foreground, app killed or killed by system will not enter here
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        #if DEBUG
        print("-->Remote Notification(RECEIVED): \(#function)")
        // do something with the notification
        print(response.notification.request.content.userInfo)
        #endif
        if userHasLoggedIn() {
            guard let notification = response.notification.request.content.userInfo as? [String: Any] else { return completionHandler() }
            self.handleNotification(notificationData: notification)
        }
        
        // the docs say you should execute this asap
        return completionHandler()
    }
}
