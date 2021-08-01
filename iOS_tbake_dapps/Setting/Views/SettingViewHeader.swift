//
//  SettingViewHeader.swift
//  AlphaWallet
//
//  Created by Nimit Parekh on 08/04/20.
//

import UIKit

class SettingViewHeader: UITableViewHeaderFooterView {
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let detailsLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .right
        return label
    }()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)

        let stackView = [
            [titleLabel, detailsLabel].asStackView(axis: .horizontal),
        ].asStackView(axis: .vertical)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.anchorsConstraint(to: contentView, edgeInsets: .init(top: 15, left: 15, bottom: 15, right: 15)),
        ])

    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(viewModel: SettingViewHeaderViewModel) {
        titleLabel.text = viewModel.titleText
        titleLabel.textColor = viewModel.titleTextColor
        titleLabel.font = viewModel.titleTextFont

        detailsLabel.text = viewModel.detailsText
        detailsLabel.textColor = viewModel.detailsTextColor
        detailsLabel.font = viewModel.detailsTextFont
    }
}
