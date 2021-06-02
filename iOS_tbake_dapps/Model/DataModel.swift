//
//  DataModel.swift
//  iOS_tbake_dapps
//
//  Created by Danial on 23/05/2021.
//

import UIKit

// MARK: - Global variable
let prefs = UserDefaults.standard
let screenHeight = UIScreen.main.bounds.height
let screenWidth = UIScreen.main.bounds.width

//for app version checking
struct AppVersionParent: Codable {
    var results: [AppVersionData]?
}

struct AppVersionData: Codable {
    var version: String?
}
