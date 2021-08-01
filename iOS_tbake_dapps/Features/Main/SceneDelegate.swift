//
//  SceneDelegate.swift
//  iOS_tbake_dapps
//
//  Created by Danial on 20/05/2021.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    private var appCoordinator: AppCoordinator!
    private let SNSPlatformApplicationArn = "arn:aws:sns:us-west-2:400248756644:app/APNS/AlphaWallet-iOS"
    private let SNSPlatformApplicationArnSANDBOX = "arn:aws:sns:us-west-2:400248756644:app/APNS_SANDBOX/AlphaWallet-testing"
    private let identityPoolId = "us-west-2:42f7f376-9a3f-412e-8c15-703b5d50b4e2"
    private let SNSSecurityTopicEndpoint = "arn:aws:sns:us-west-2:400248756644:security"
    //This is separate coordinator for the protection of the sensitive information.
    private lazy var protectionCoordinator: ProtectionCoordinator = {
        return ProtectionCoordinator()
    }()

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        //setup window scene
        self.window = UIWindow(windowScene: windowScene)
    
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        //Lokalise.shared.checkForUpdates { _, _ in }
    }

    func sceneWillResignActive(_ scene: UIScene) {
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
    }
    
    
    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        // Get URL components from the incoming user activity
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb, let incomingURL = userActivity.webpageURL, let components = NSURLComponents(url: incomingURL, resolvingAgainstBaseURL: true) else {
            return
        }
        
        // Check for specific URL components that you need
        let params = components.queryItems
        
        print("\(String(describing: params))")
    }
    
    func setDarkMode(isDark: Bool) {
        self.window?.overrideUserInterfaceStyle = isDark ? .dark : .light
    }
    
    func getTopMostViewController() -> UIViewController? {
        if var topController = self.window?.rootViewController {
            while let presentedViewController = topController.presentedViewController {
                topController = presentedViewController
            }

            return topController
        }
        
        return self.window?.rootViewController ?? nil
    }
}

