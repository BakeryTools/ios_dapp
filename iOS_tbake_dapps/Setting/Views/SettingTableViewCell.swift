//
//  SettingTableViewCell.swift
//  AlphaWallet
//
//  Created by Nimit Parekh on 06/04/20.
//

import UIKit

class SettingTableViewCell: UITableViewCell {
    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.clipsToBounds = true
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.clipsToBounds = false

        return label
    }()

    private let subTitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.clipsToBounds = false

        return label
    }()
    
    let parentView = UIView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        accessoryType = .disclosureIndicator

        let stackView = [
            titleLabel,
            subTitleLabel
        ].asStackView(axis: .vertical, spacing: 5)

        stackView.translatesAutoresizingMaskIntoConstraints = false

        let stackViewParent = [
            iconImageView,
            .spacerWidth(10),
            stackView,
        ].asStackView(axis: .horizontal)
        stackViewParent.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(stackViewParent)
       
        NSLayoutConstraint.activate([
            iconImageView.widthAnchor.constraint(equalToConstant: 40),
            iconImageView.heightAnchor.constraint(equalToConstant: 40),
            
            stackViewParent.anchorsConstraint(to: contentView, edgeInsets: .init(top: 15, left: 15, bottom: 15, right: 15)),
        ])
    }

    override func prepareForReuse() {
        accessoryView = nil
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(viewModel: SettingTableViewCellViewModel) {
        titleLabel.text = viewModel.titleText
        titleLabel.font = viewModel.titleFont
        titleLabel.textColor = viewModel.titleTextColor
        iconImageView.image = viewModel.icon
        iconImageView.tintColor = Colors.tbakeDarkBrown
        subTitleLabel.text = viewModel.subTitleText
        subTitleLabel.isHidden = viewModel.subTitleHidden
        subTitleLabel.font = viewModel.subTitleFont
        subTitleLabel.textColor = viewModel.subTitleTextColor
        contentView.backgroundColor = Colors.backgroundClear
        backgroundColor = Colors.backgroundClear
    }
}
