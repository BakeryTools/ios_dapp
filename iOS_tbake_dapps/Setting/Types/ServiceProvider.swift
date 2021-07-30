// Copyright SIX DAY LLC. All rights reserved.

import Foundation
import UIKit

enum URLServiceProvider {
    case telegramAnnouncement
    case telegramGroup
    case twitter
    case website
    case medium
    case github

    var title: String {
        switch self {
        case .telegramAnnouncement:
            return "Telegram Announcement"
        case .telegramGroup:
            return "Telegram Group"
        case .twitter:
            return "Twitter"
        case .website:
            return "Website"
        case .medium:
            return "Medium"
        case .github:
            return "Github"
        }
    }

    //TODO should probably change or remove `localURL` since iOS supports deep links now
    var localURL: URL? {
        switch self {
        case .telegramAnnouncement:
            return URL(string: "https://t.me/BakeryToolsann")!
        case .telegramGroup:
            return URL(string: "https://t.me/mybakerytools")!
        case .twitter:
            return URL(string: "https://twitter.com/\(Constants.twitterUsername)")!
        case .website:
            return URL(string: "https://bakerytools.io")
        case .medium:
            return URL(string: "https://bakerytools.medium.com")!
        case .github:
            return URL(string: "https://github.com/bakerytools")!
        }
    }

    var remoteURL: URL {
        switch self {
        case .telegramAnnouncement:
            return URL(string: "https://t.me/BakeryToolsann")!
        case .telegramGroup:
            return URL(string: "https://t.me/mybakerytools")!
        case .twitter:
            return URL(string: "twitter://user?screen_name=\(Constants.twitterUsername)")!
        case .website:
            return URL(string: "https://bakerytools.io")!
        case .medium:
            return URL(string: "https://bakerytools.medium.com")!
        case .github:
            return URL(string: "https://github.com/bakerytools")!
        }
    }

    var image: UIImage? {
        switch self {
        case .telegramAnnouncement, .telegramGroup:
            return R.image.settings_telegram()
        case .twitter:
            return R.image.settings_twitter()
        case .website:
            return R.image.globe()
        case .medium:
            return R.image.medium_logo()
        case .github:
            return R.image.github_logo()
        }
    }
}
