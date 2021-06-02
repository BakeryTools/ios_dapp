//
//  Utilities.swift
//  iOS_tbake_dapps
//
//  Created by Danial on 23/05/2021.
//
import UIKit

//MARK:- Global Function
func getMainViewController() -> MainViewController? {
    if let tabBarController = UIApplication.shared.keyWindow?.rootViewController as? MainViewController {
        return tabBarController
    }
    
    return nil
}

func setRippleTransition() -> CATransition {
    let animation = CATransition()
    animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut)
    animation.subtype = .fromTop
    animation.type = CATransitionType(rawValue: "rippleEffect")
    animation.duration = 0.6
    animation.startProgress = 0.25
    animation.endProgress = 1
    
    return animation
}

func isJailbroken() -> Bool {
    
    guard let cydiaUrlScheme = NSURL(string: "cydia://package/com.example.package") else { return false }
    if UIApplication.shared.canOpenURL(cydiaUrlScheme as URL) {
        return true
    }
    
    #if arch(i386) || arch(x86_64)
    // This is a Simulator not an idevice
    
    return false
    
    #else
    
    let fileManager = FileManager.default
    if fileManager.fileExists(atPath: "/Applications/Cydia.app") ||
        fileManager.fileExists(atPath: "/Library/MobileSubstrate/MobileSubstrate.dylib") ||
        fileManager.fileExists(atPath: "/bin/bash") ||
        fileManager.fileExists(atPath: "/usr/sbin/sshd") ||
        fileManager.fileExists(atPath: "/etc/apt") ||
        fileManager.fileExists(atPath: "/usr/bin/ssh") ||
        fileManager.fileExists(atPath: "/private/var/lib/apt") {
        return true
    }
    
    if isJailbrokenCanOpen(path: "/Applications/Cydia.app") ||
        isJailbrokenCanOpen(path: "/Library/MobileSubstrate/MobileSubstrate.dylib") ||
        isJailbrokenCanOpen(path: "/bin/bash") ||
        isJailbrokenCanOpen(path: "/usr/sbin/sshd") ||
        isJailbrokenCanOpen(path: "/etc/apt") ||
        isJailbrokenCanOpen(path: "/usr/bin/ssh") {
        return true
    }
    
    let path = "/private/" + NSUUID().uuidString
    do {
        try "anyString".write(toFile: path, atomically: true, encoding: String.Encoding.utf8)
        try fileManager.removeItem(atPath: path)
        return true
    } catch {
        return false
    }
    
    #endif
}

func isJailbrokenCanOpen(path: String) -> Bool {
    let file = fopen(path, "r")
    guard file != nil else { return false }
    fclose(file)
    return true
}

func isFirstTime() -> Bool {
    return !UserPrefs.isFirstTime.boolValue
}

func checkAppUpdate(_ completion: @escaping ()->Void) {
    let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    let bundleId = Bundle.main.infoDictionary!["CFBundleIdentifier"] as! String
    let jsonUrlString = "https://itunes.apple.com/id/lookup?bundleId=\(bundleId)"
    
    WebService().getData(jsonUrlString){ data in
        do {
            let data = try JSONDecoder().decode(AppVersionParent.self, from: data)
            
            if data.results?.count ?? 0 > 0 {
                let appVersion = data.results?[0].version ?? ""
                
                //orderedAscending = < targetVersion (1.0.0 & 1.0.1)
                //orderedDescending = > targetVersion (1.1.0 & 1.0.10)
                if currentVersion?.compare(appVersion, options: .numeric) == .orderedAscending {
                    completion()
                }
            }
            
        }catch let error {
            print(error)
            
        }
    }
}

//MARK:- End Global Function


//MARK:- Get Data
func getDeviceId() -> String {
    return UIDevice.current.identifierForVendor?.uuidString ?? ""
}

func getNotificationBadge() -> Int {
    return UserPrefs.notificationCount.intValue
}

func userHasLoggedIn() -> Bool {
    return UserPrefs.isLoggedIn.boolValue
}

func getUserToken() -> String {
    return UserPrefs.userToken.stringValue
}