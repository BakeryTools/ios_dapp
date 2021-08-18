// Copyright © 2018 Stormbird PTE. LTD.
import UIKit

protocol SendHeaderViewDelegate: AnyObject {
    func didPressViewContractWebPage(inHeaderView: SendHeaderView)
    func showHideMarketPriceSelected(inHeaderView: SendHeaderView)
}

class SendHeaderView: UIView {

    weak var delegate: SendHeaderViewDelegate?

    private var tokenIconImageView: TokenImageView = {
        let imageView = TokenImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.isUserInteractionEnabled = true
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.textAlignment = .center
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)

        return label
    }()

    private var blockChainTagLabel = BlockchainTagLabel()

    init() {
        super.init(frame: .zero)

        let stackView = [
            tokenIconImageView,
            titleLabel,
            blockChainTagLabel
        ].asStackView(axis: .vertical, spacing: 10, alignment: .center)

        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)

        NSLayoutConstraint.activate([
            tokenIconImageView.heightAnchor.constraint(equalToConstant: DataEntry.Metric.SendHeader.iconSide),
            tokenIconImageView.widthAnchor.constraint(equalToConstant: DataEntry.Metric.SendHeader.iconSide),
            stackView.anchorsConstraint(to: self, edgeInsets: DataEntry.Metric.SendHeader.insets)
        ])

        let tap = UITapGestureRecognizer(target: self, action: #selector(showContractWebPage))
        tokenIconImageView.addGestureRecognizer(tap)
    }

    required init?(coder aDecoder: NSCoder) {
        return nil
    }

    func configure(viewModel: TokenInfoPageViewModel) {
        backgroundColor = viewModel.backgroundColor

        tokenIconImageView.subscribable = viewModel.iconImage
        titleLabel.attributedText = viewModel.titleAttributedString
        blockChainTagLabel.configure(viewModel: viewModel.blockChainTagViewModel)
    }

    @objc private func showContractWebPage() {
        delegate?.didPressViewContractWebPage(inHeaderView: self)
    }

    @objc private func showHideMarketSelected(_ sender: UITapGestureRecognizer) {
        delegate?.showHideMarketPriceSelected(inHeaderView: self)
    }
}
