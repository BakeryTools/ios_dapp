// Copyright © 2018 Stormbird PTE. LTD.

import UIKit
import AssistantKit

extension TBakeWallet {
    typealias Device = AssistantKit.Device
    typealias Screen = AssistantKit.Screen
}

class ScreenChecker {
	//Smaller width than iPhone 6 (i.e iPhone 5). Some text wouldn't fit nicely
	var isNarrowScreen: Bool {
		let iPhone6Width = CGFloat(375)
		return UIScreen.main.bounds.width < iPhone6Width
	}

	var isBigScreen: Bool {
		return UIScreen.main.bounds.width >= 768 && UIScreen.main.bounds.height >= 768
	}
}

extension ScreenChecker {

    /// Return size for family value
    ///- parameter old: .inches_3_5, .inches_4_0
    ///- parameter small: .inches_4_7
    ///- parameter medium: .inches_5_4, .inches_5_5, .inches_7_9, .inches_5_8, .inches_6_1, .inches_6_5, .inches_6_7
    ///- parameter big: .inches_9_7, .inches_10_2, .inches_10_5, .inches_10_9, .inches_11, .inches_12_9
    static func size(big: CGFloat, medium: CGFloat, small: CGFloat) -> CGFloat {
        return Device.size(small: small, medium: medium, big: big)
    }
}
