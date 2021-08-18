// Copyright © 2020 Stormbird PTE. LTD.

import UIKit

struct SegmentedControlViewModel {
	var selection: SegmentedControl.Selection

	init(selection: SegmentedControl.Selection) {
		self.selection = selection
	}

	var backgroundColor: UIColor {
		return Colors.backgroundClear
	}

	func titleFont(forSelection selection: SegmentedControl.Selection) -> UIFont {
		if selection == self.selection {
			return selectedTitleFont
		} else {
			return unselectedTitleFont
		}
	}

	func titleColor(forSelection selection: SegmentedControl.Selection) -> UIColor {
		if selection == self.selection {
			return selectedTitleColor
		} else {
            return unselectedTitleColor
		}
	}

	private var unselectedTitleFont: UIFont {
        return Screen.TokenCard.Font.subtitle
	}

	private var selectedTitleFont: UIFont {
        return Screen.TokenCard.Font.title
	}

	private var unselectedTitleColor: UIColor {
        return Colors.appText
	}

	private var selectedTitleColor: UIColor {
		return selectedBarColor
	}

	var unselectedBarColor: UIColor {
		return Colors.appBackground
	}

	var selectedBarColor: UIColor {
		return Colors.tbakeDarkBrown
	}
}
