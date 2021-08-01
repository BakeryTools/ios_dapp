// Copyright © 2018 Stormbird PTE. LTD.

import Foundation
import UIKit

class BrowserHistoryCell: UITableViewCell {
    private var viewModel: BrowserHistoryCellViewModel?
    private var iconImageViewHolder = ContainerViewWithShadow(aroundView: UIImageView())
    private let titleLabel = UILabel()
    private let urlLabel = UILabel()
    private let backgroundCellView = UIView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)

        let labelsVerticalStackView = [
            titleLabel,
            urlLabel ].asStackView(axis: .vertical)

        let mainStackView = [.spacerWidth(5), iconImageViewHolder, .spacerWidth(20), labelsVerticalStackView, .spacerWidth(29)].asStackView(axis: .horizontal, alignment: .center)
        mainStackView.translatesAutoresizingMaskIntoConstraints = false
        
        self.backgroundCellView.addSubview(mainStackView)
        self.backgroundCellView.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(self.backgroundCellView)

        NSLayoutConstraint.activate([
            mainStackView.leadingAnchor.constraint(equalTo: self.backgroundCellView.leadingAnchor),
            mainStackView.trailingAnchor.constraint(equalTo: self.backgroundCellView.trailingAnchor),
            mainStackView.topAnchor.constraint(equalTo: self.backgroundCellView.topAnchor, constant: 7),
            mainStackView.bottomAnchor.constraint(equalTo: self.backgroundCellView.bottomAnchor, constant: -7),
            
            self.backgroundCellView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            self.backgroundCellView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            self.backgroundCellView.topAnchor.constraint(equalTo: contentView.topAnchor),
            self.backgroundCellView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -7),

            iconImageViewHolder.widthAnchor.constraint(equalToConstant: 44),
            iconImageViewHolder.widthAnchor.constraint(equalTo: iconImageViewHolder.heightAnchor),
        ])
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(viewModel: BrowserHistoryCellViewModel) {
        self.viewModel = viewModel

        self.backgroundCellView.backgroundColor = Colors.appBackground

        iconImageViewHolder.configureShadow(color: viewModel.imageViewShadowColor, offset: viewModel.imageViewShadowOffset, opacity: viewModel.imageViewShadowOpacity, radius: viewModel.imageViewShadowRadius, cornerRadius: iconImageViewHolder.frame.size.width / 2)

        let iconImageView = iconImageViewHolder.childView
        iconImageView.backgroundColor = viewModel.backgroundColor
        iconImageView.contentMode = .scaleAspectFill
        iconImageView.clipsToBounds = true
        iconImageView.kf.setImage(with: viewModel.imageUrl, placeholder: viewModel.fallbackImage)

        titleLabel.font = viewModel.nameFont
        titleLabel.textColor = viewModel.nameColor
        titleLabel.text = viewModel.name

        urlLabel.font = viewModel.urlFont
        urlLabel.textColor = viewModel.urlColor
        urlLabel.text = viewModel.url

        //TODO ugly hack to get the image view's frame. Can't figure out a good point to retrieve the correct frame otherwise
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            self.iconImageViewHolder.configureShadow(color: viewModel.imageViewShadowColor, offset: viewModel.imageViewShadowOffset, opacity: viewModel.imageViewShadowOpacity, radius: viewModel.imageViewShadowRadius, cornerRadius: self.iconImageViewHolder.frame.size.width / 2)
        }
    }
}
