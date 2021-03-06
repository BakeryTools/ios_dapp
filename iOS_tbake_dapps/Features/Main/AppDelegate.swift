//
//  AppDelegate.swift
//  iOS_tbake_dapps
//
//  Created by Danial on 20/05/2021.
//

import UIKit
import RealmSwift
import AWSSNS
import AWSCore
import UserNotifications
import IQKeyboardManagerSwift
import AppTrackingTransparency

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    
    private var appCoordinator: AppCoordinator!
    private let SNSPlatformApplicationArn = "" //"arn:aws:sns:us-west-2:400248756644:app/APNS/AlphaWallet-iOS"
    private let SNSPlatformApplicationArnSANDBOX =  "" //"arn:aws:sns:us-west-2:400248756644:app/APNS_SANDBOX/AlphaWallet-testing"
    private let identityPoolId = "" //"us-west-2:42f7f376-9a3f-412e-8c15-703b5d50b4e2"
    private let SNSSecurityTopicEndpoint = ""//"arn:aws:sns:us-west-2:400248756644:security"
    //This is separate coordinator for the protection of the sensitive information.
    private lazy var protectionCoordinator: ProtectionCoordinator = {
        return ProtectionCoordinator()
    }()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        //implements keyboard handling
        IQKeyboardManager.shared.enable = true
        IQKeyboardManager.shared.shouldResignOnTouchOutside = true
        
        IQKeyboardManager.shared.disabledTouchResignedClasses.append(LockPasscodeViewController.self)
        IQKeyboardManager.shared.disabledToolbarClasses.append(LockPasscodeViewController.self)
        
        
        window = UIWindow(frame: UIScreen.main.bounds)
        //Necessary to make UIAlertController have the correct tint colors, despite already doing: `UIWindow.appearance().tintColor = Colors.appTint`
        window?.tintColor = Colors.appTint
        
        // set dark mode according to user preferences
        let darkMode = UserDefaults.standard.bool(forKey: "darkMode")
        self.setDarkMode(isDark: darkMode)
        
        // Shake to share report
        let appName = Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        let deviceVersion = UIDevice.current.systemVersion
        let deviceModel = UIDevice.modelName
        let mobileId = UIDevice.current.identifierForVendor?.uuidString
        
        BugShaker.configure(to: ["a.danial0606@gmail.com"], subject: "BakeryTools iOS App Bug Report / Feedback", body: """
            <strong>App Version:</strong> \(appName ?? "") (v\(appVersion ?? ""))<br/>
            <strong>iOS Version:</strong> \(deviceVersion)<br/>
            <strong>Device Model:</strong> \(deviceModel)<br/>
            <strong>Mobile ID:</strong> \(mobileId ?? "")<br/>
            """
        )
        
        
        PushNotificationsRegistration()
        UIApplication.shared.registerForRemoteNotifications()
        // set app delegate as notification center delegate
        // this is IMPORTANT for handling notification in background and foreground
        UNUserNotificationCenter.current().delegate = self

        do {
            //NOTE: we move AnalyticsService creation from AppCoordinator.init method to allow easily replace
            let analyticsService = AnalyticsService()
            let keystore = try EtherKeystore(analyticsCoordinator: analyticsService)
            let navigationController = UINavigationController()
            navigationController.view.backgroundColor = Colors.appWhite

            appCoordinator = try AppCoordinator(window: window!, analyticsService: analyticsService, keystore: keystore, navigationController: navigationController)
            appCoordinator.start()

            if let shortcutItem = launchOptions?[UIApplication.LaunchOptionsKey.shortcutItem] as? UIApplicationShortcutItem, shortcutItem.type == Constants.launchShortcutKey {
                //Delay needed to work because app is launching..
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.appCoordinator.launchUniversalScanner()
                }
            }
        } catch {

        }
        
        protectionCoordinator.didFinishLaunchingWithOptions()

        return true
    }

    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        if shortcutItem.type == Constants.launchShortcutKey {
            appCoordinator.launchUniversalScanner()
        }
        completionHandler(true)
    }

    private func cognitoRegistration() {
        // Override point for customization after application launch.
        /// Setup AWS Cognito credentials
        // Initialize the Amazon Cognito credentials provider
        let credentialsProvider = AWSCognitoCredentialsProvider(regionType: .USWest2,
                identityPoolId: identityPoolId)
        let configuration = AWSServiceConfiguration(region: .USWest2, credentialsProvider: credentialsProvider)
        AWSServiceManager.default().defaultServiceConfiguration = configuration
        let defaultServiceConfiguration = AWSServiceConfiguration(
                region: AWSRegionType.USWest2, credentialsProvider: credentialsProvider)
        AWSServiceManager.default().defaultServiceConfiguration = defaultServiceConfiguration
    }

    func applicationWillResignActive(_ application: UIApplication) {
        protectionCoordinator.applicationWillResignActive()
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        //Lokalise.shared.checkForUpdates { _, _ in }
        protectionCoordinator.applicationDidBecomeActive()
        appCoordinator.handleUniversalLinkInPasteboard()
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        protectionCoordinator.applicationDidEnterBackground()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        protectionCoordinator.applicationWillEnterForeground()
    }

    func application(_ application: UIApplication, shouldAllowExtensionPointIdentifier extensionPointIdentifier: UIApplication.ExtensionPointIdentifier) -> Bool {
        if extensionPointIdentifier == .keyboard {
            return false
        }
        return true
    }

    // URI scheme links and AirDrop
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        return appCoordinator.handleOpen(url: url)
    }

    // Respond to Universal Links
    func application(_ application: UIApplication,
                     continue userActivity: NSUserActivity,
                     restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        var handled = false
        if let url = userActivity.webpageURL {
            handled = handleUniversalLink(url: url)
        }
        //TODO: if we handle other types of URLs, check if handled==false, then we pass the url to another handlers
        return handled
    }

    // Respond to amazon SNS registration
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        /// Attach the device token to the user defaults
        var token = ""
        for i in 0..<deviceToken.count {
            let tokenInfo = String(format: "%02.2hhx", arguments: [deviceToken[i]])
            token.append(tokenInfo)
        }
        UserDefaults.standard.set(token, forKey: "deviceTokenForSNS")
        /// Create a platform endpoint. In this case, the endpoint is a
        /// device endpoint ARN
        cognitoRegistration()
        let sns = AWSSNS.default()
        let request = AWSSNSCreatePlatformEndpointInput()
        request?.token = token
        #if DEBUG
            request?.platformApplicationArn = SNSPlatformApplicationArnSANDBOX
        #else
            request?.platformApplicationArn = SNSPlatformApplicationArn
        #endif

        sns.createPlatformEndpoint(request!).continueWith(executor: AWSExecutor.mainThread(), block: { (task: AWSTask!) -> AnyObject? in
            if task.error == nil {
                let createEndpointResponse = task.result! as AWSSNSCreateEndpointResponse
                if let endpointArnForSNS = createEndpointResponse.endpointArn {
                    UserDefaults.standard.set(endpointArnForSNS, forKey: "endpointArnForSNS")
                    //every user should subscribe to the security topic
                    self.subscribeToTopicSNS(token: token, topicEndpoint: self.SNSSecurityTopicEndpoint)
//                    if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
//                        //TODO subscribe to version topic when created
//                    }
                }
            }
            return nil
        })
    }
    
    func setDarkMode(isDark: Bool) {
        self.window?.overrideUserInterfaceStyle = isDark ? .dark : .light
    }

    func subscribeToTopicSNS(token: String, topicEndpoint: String) {
        let sns = AWSSNS.default()
        guard let endpointRequest = AWSSNSCreatePlatformEndpointInput() else { return }
        #if DEBUG
            endpointRequest.platformApplicationArn = SNSPlatformApplicationArnSANDBOX
        #else
            endpointRequest.platformApplicationArn = SNSPlatformApplicationArn
        #endif
        endpointRequest.token = token

        sns.createPlatformEndpoint(endpointRequest).continueWith { task in
            guard let response: AWSSNSCreateEndpointResponse = task.result else { return nil }
            guard let subscribeRequest = AWSSNSSubscribeInput() else { return nil }
            subscribeRequest.endpoint = response.endpointArn
            subscribeRequest.protocols = "application"
            subscribeRequest.topicArn = topicEndpoint
            return sns.subscribe(subscribeRequest)
        }
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

    //TODO Handle SNS errors
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        #if DEBUG
        print("Failed to register: \(error)")
        #endif
    }

    @discardableResult private func handleUniversalLink(url: URL) -> Bool {
        let handled = appCoordinator.handleUniversalLink(url: url)
        return handled
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
        
        // the docs say you should execute this asap
        return completionHandler()
    }
}
