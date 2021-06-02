//
//  SceneDelegate.swift
//  iOS_tbake_dapps
//
//  Created by Danial on 20/05/2021.
//

import UIKit
import Network

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    let monitor = NWPathMonitor()

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        //setup window scene
        self.window = UIWindow(windowScene: windowScene)
        
        // set dark mode according to user preferences
        let darkMode = UserDefaults.standard.bool(forKey: "darkMode")
        self.setDarkMode(isDark: darkMode)
        
        self.initLaunchPage()
        
        //setup for network detection
        let queue = DispatchQueue.global(qos: .background)
        monitor.start(queue: queue)
        
        //check if user from remote notification
        let notificationOptions = connectionOptions.notificationResponse
        
        if notificationOptions != nil {
            if userHasLoggedIn() {
                guard let notification = notificationOptions?.notification.request.content.userInfo as? [String: Any] else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) { //delayed a bit for splash screen
                    AppDelegate().handleNotification(notificationData: notification)
                }
            }
        }
        
        //check if user from universal link
        if let userActivity = connectionOptions.userActivities.first {
             DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) { //delayed a bit for splash screen
                self.scene(scene, continue: userActivity)
            }
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
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
    
    func trackNetworkConnectionStatus() {
        //check if open app with connection or not
        if monitor.currentPath.status == .unsatisfied { //if no connection, show no connection nib
            print("No Connection")
//            DispatchQueue.main.async {
//                if let _ = self.getTopMostViewController() as? NoConnection { return } //check if no connection page alrdy displayed
//                let nib = NoConnection(nibName: "NoConnection", bundle: nil)
//                nib.modalPresentationStyle = .fullScreen
//                self.getTopMostViewController()?.present(nib, animated: true, completion: nil)
//            }
        }
        
        //start monitor for network changes
        monitor.pathUpdateHandler = { path in
            if path.status == .unsatisfied {
                print("No Connection")
//                DispatchQueue.main.async {
//                    if let _ = self.getTopMostViewController() as? NoConnection { return } //check if no connection page alrdy displayed
//                    let nib = NoConnection(nibName: "NoConnection", bundle: nil)
//                    nib.modalPresentationStyle = .fullScreen
//                    self.getTopMostViewController()?.present(nib, animated: true, completion: nil)
//                }
            }
        }
    }
    
    func setDarkMode(isDark: Bool) {
        self.window?.overrideUserInterfaceStyle = isDark ? .dark : .light
    }
    
    func checkNetworkConnection() {
        if monitor.currentPath.status == .satisfied {
            DispatchQueue.main.async {
                self.getTopMostViewController()?.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    func initLaunchPage() {
        let vc = SplashScreenViewController()
        self.window?.rootViewController = vc
        self.window?.makeKeyAndVisible()
    }
    
    func initRootController() {

        self.window?.layer.add(setRippleTransition(), forKey: "")
        
        let mainStoryboard : UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        guard let vc = mainStoryboard.instantiateViewController(withIdentifier: "TabBar") as? UITabBarController else { return }
        vc.selectedIndex = 0
        self.window?.rootViewController = vc
        self.window?.makeKeyAndVisible()
        
        self.trackNetworkConnectionStatus()
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

