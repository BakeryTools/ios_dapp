// Copyright © 2019 Stormbird PTE. LTD.

import Foundation
import UIKit

extension TokensViewController {
    class TableViewSectionHeader: UITableViewHeaderFooterView {
        var filterView: SegmentedControl? {
            didSet {
                guard let filterView = filterView else {
                    if let oldValue = oldValue {
                        oldValue.removeFromSuperview()
                    }
                    return
                }
                filterView.backgroundColor = Colors.appBackground
                filterView.translatesAutoresizingMaskIntoConstraints = false
                contentView.addSubview(filterView)
                NSLayoutConstraint.activate([
                    filterView.anchorsConstraint(to: contentView),
                ])
            }
        }

        override init(reuseIdentifier: String?) {
            super.init(reuseIdentifier: reuseIdentifier)
            contentView.backgroundColor = Colors.appBackground
        }

        required init?(coder aDecoder: NSCoder) {
            return nil
        }
    }
}
