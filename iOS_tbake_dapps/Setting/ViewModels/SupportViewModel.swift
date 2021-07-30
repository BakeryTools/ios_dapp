//
//  SupportViewModel.swift
//  AlphaWallet
//
//  Created by Vladyslav Shepitko on 04.06.2020.
//

import UIKit

class SupportViewModel: NSObject {

    var title: String {
        R.string.localizable.settingsSocialMediaTitle()
    }
    
    var rows: [SupportRow] = [.telegramAnnouncement, .telegramGroup, .twitter, .website, .medium, .github]
    
    func cellViewModel(indexPath: IndexPath) -> SettingTableViewCellViewModel {
        let row = rows[indexPath.row]
        return .init(titleText: row.title, subTitleText: nil, icon: row.image)
    }
}

enum SupportRow {
    case telegramAnnouncement
    case telegramGroup
    case twitter
    case website
    case medium
    case github
    
    var urlProvider: URLServiceProvider? {
        switch self {
        case .telegramAnnouncement:
            return URLServiceProvider.telegramAnnouncement
        case .telegramGroup:
            return URLServiceProvider.telegramGroup
        case .twitter:
            return URLServiceProvider.twitter
        case .website:
            return URLServiceProvider.website
        case .github:
            return URLServiceProvider.github
        case .medium:
            return URLServiceProvider.medium
        }
    }
    
    var title: String {
        switch self {
        case .telegramAnnouncement:
            return URLServiceProvider.telegramAnnouncement.title
        case .telegramGroup:
            return URLServiceProvider.telegramGroup.title
        case .twitter:
            return URLServiceProvider.twitter.title
        case .website:
            return URLServiceProvider.website.title
        case .github:
            return URLServiceProvider.github.title
        case .medium:
            return URLServiceProvider.medium.title
        }
    }
    
    var image: UIImage {
        switch self {
        case .telegramAnnouncement, .telegramGroup:
            return URLServiceProvider.telegramAnnouncement.image!
        case .twitter:
            return URLServiceProvider.twitter.image!
        case .website:
            return URLServiceProvider.website.image!
        case .github:
            return URLServiceProvider.github.image!
        case .medium:
            return URLServiceProvider.medium.image!
        }
    }
} 
