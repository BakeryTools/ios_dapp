//
//  UserDefaultsManager.swift
//  iOS_tbake_dapps
//
//  Created by Danial on 23/05/2021.
//  Copyright © 2021 Danial. All rights reserved.
//

import Foundation
import SwiftKeychainWrapper

enum UserPrefsType {
    
    case logout
    case profile
    
}

struct UserPrefs {
   
    struct UserPrefsKeychainWrapperObj {
        
        let key: String!
        
        init(_ key: String) {
            self.key = key
        }
        
        func set(_ value: String?) {
            KeychainWrapper.standard.set(value ?? "", forKey: key)
        }
        
        func clear(){
            KeychainWrapper.standard.removeObject(forKey: key)
        }
        
        var stringValue: String {
            if let stringValue = KeychainWrapper.standard.string(forKey: self.key) {
                return stringValue
            }
            return ""
        }
        
    }

    
    struct UserPrefsObj {
        
        let key: String!
        
        init(_ key: String) {
            self.key = key
        }
        
        func set(_ value: Any?) {
            UserDefaults.standard.set(value, forKey: key)
        }
        
        func clear(){
            UserDefaults.standard.removeObject(forKey: key)
        }
        
        var value: Any? {
            if let value = UserDefaults.standard.value(forKey: self.key) {
                return value
            }
            return nil
        }
        
        var arrayValue: [Any]? {
            if let arrayValue = UserDefaults.standard.array(forKey: self.key) {
                return arrayValue
            }
            return nil
        }
        
        var stringValue: String {
            if let stringValue = UserDefaults.standard.string(forKey: self.key) {
                return stringValue
            }
            return ""
        }
        
        var dictValue: [String : Any]? {
            return UserDefaults.standard.dictionary(forKey: self.key)
        }
        
        var intValue: Int {
            let intValue = UserDefaults.standard.integer(forKey: self.key)
            return intValue
        }
        
        var boolValue: Bool {
            return UserDefaults.standard.bool(forKey: self.key)
        }
        
    }
    
    // MARK: - Variables Keychain Wrapper
    static private let logoutKeychainPrefs: [UserPrefsKeychainWrapperObj] = [
        
        UserPrefs.userToken,
        UserPrefs.userEmail,
    ]
    
    // MARK: - Variables
    static private let logoutPrefs: [UserPrefsObj] = [
        
        UserPrefs.showAppRatingPerSession,
        UserPrefs.isLoggedIn,
        UserPrefs.notificationCount
        
    ]
    
    static private let profilePrefs: [UserPrefsObj] = [
        
        UserPrefs.showAppRatingPerSession,
        UserPrefs.isLoggedIn,
        UserPrefs.notificationCount
    ]
    
    // values keychain wrapper
    static let userToken = UserPrefsKeychainWrapperObj("userToken")
    
    //user related data
    static let userEmail = UserPrefsKeychainWrapperObj("userEmail")
    
    // values that not being reset
    static let appEnvironment = UserPrefsObj("appEnvironment")
    static let isFirstTime = UserPrefsObj("isFirstTime")
    
    // value that will reset
    static let showAppRatingPerSession = UserPrefsObj("showAppRatingPerSession")
    static let isLoggedIn = UserPrefsObj("isLoggedIn")
    static let notificationCount = UserPrefsObj("notificationCount")
    
    // MARK: - Functions
    static func clearUserPrefs(type: UserPrefsType, appleLogout: Bool, completion: (() -> Void)? = nil) {
        switch type {
            
        case .logout:
            
            for prefsObj in logoutPrefs {
                if prefsObj.key == UserPrefs.isLoggedIn.key {
                    prefsObj.set(0)
                    continue
                }else if prefsObj.stringValue == UserPrefs.notificationCount.stringValue {
                    prefsObj.clear()
                    NotificationCenter.default.post(Notification(name: Notification.Name("didReceiveNotification")))
                }
                
                prefsObj.clear()
            }
            
            for prefsObj in logoutKeychainPrefs {
                prefsObj.clear()
            }
            
            completion?()
            
        case .profile:
            
            for prefsObj in profilePrefs {
                prefsObj.set("")
            }
        }
    }
}
