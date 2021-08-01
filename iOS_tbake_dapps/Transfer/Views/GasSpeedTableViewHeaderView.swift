//
//  GasSpeedTableViewHeaderView.swift
//  AlphaWallet
//
//  Created by Vladyslav Shepitko on 25.08.2020.
//

import UIKit

class GasSpeedTableViewHeaderView: UITableViewHeaderFooterView {

    static let height = CGFloat(50)
    static let contentInsets: UIEdgeInsets = {
        let topBottomInset: CGFloat = ScreenChecker().isNarrowScreen ? 8 : 16
        let sideInset: CGFloat = ScreenChecker().isNarrowScreen ? 5 : 10

        return .init(top: sideInset, left: topBottomInset, bottom: sideInset, right: topBottomInset)
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        return label
    }()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)

        let stackView = [
            titleLabel,
        ].asStackView(axis: .vertical)

        stackView.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.anchorsConstraint(to: contentView, edgeInsets: GasSpeedTableViewHeaderView.contentInsets)
        ])
    }

    required init?(coder: NSCoder) {
        return nil
    }

    func configure(viewModel: GasSpeedTableViewHeaderViewModel) {
        titleLabel.attributedText = viewModel.titleAttributedString
        contentView.backgroundColor = viewModel.backgroundColor
    }
}
