//
//  ConfirmationHeaderView.swift
//  AlphaWallet
//
//  Created by Vladyslav Shepitko on 22.02.2021.
//

import UIKit

class ConfirmationHeaderView: UIView {
    private let separatorLine: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = R.color.mercury()

        return view
    }()

    private let titleLabel: UILabel = {
        let titleLabel = UILabel(frame: .zero)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        return titleLabel
    }()

    let closeButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.contentMode = .scaleAspectFit
        button.setImage(R.image.close(), for: .normal)

        return button
    }()

    init(viewModel: ConfirmationHeaderViewModel) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false

        addSubview(separatorLine)
        addSubview(titleLabel)
        addSubview(closeButton)

        NSLayoutConstraint.activate([
            separatorLine.heightAnchor.constraint(equalToConstant: DataEntry.Metric.TransactionConfirmation.separatorHeight),
            separatorLine.bottomAnchor.constraint(equalTo: bottomAnchor),
            separatorLine.leadingAnchor.constraint(equalTo: leadingAnchor),
            separatorLine.trailingAnchor.constraint(equalTo: trailingAnchor),

            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor),

            closeButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            closeButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: 30),
            closeButton.heightAnchor.constraint(equalToConstant: 30),

            heightAnchor.constraint(equalToConstant: DataEntry.Metric.TransactionConfirmation.headerHeight)
        ])

        titleLabel.attributedText = viewModel.attributedTitle
        backgroundColor = viewModel.backgroundColor
        separatorLine.isHidden = viewModel.isMinimalMode
    }

    required init?(coder: NSCoder) {
        return nil
    }
}
