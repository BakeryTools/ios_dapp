// Copyright SIX DAY LLC. All rights reserved.

import Foundation
import UIKit
import StatefulViewController

class TransactionsEmptyView: UIView {
    private let titleLabel = UILabel()
    private let imageView = UIImageView()
    private let button = Button(size: .normal, style: .solid)
    private let insets: UIEdgeInsets
    private var onRetry: (() -> Void)? = .none
    private let viewModel = StateViewModel()

    init(
        title: String = R.string.localizable.transactionsNoTransactionsLabelTitle(),
        image: UIImage? = R.image.no_transactions_mascot(),
        insets: UIEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0),
        onRetry: (() -> Void)? = .none
    ) {
        self.insets = insets
        self.onRetry = onRetry
        super.init(frame: .zero)

        backgroundColor = .white

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = title
        titleLabel.font = viewModel.descriptionFont
        titleLabel.textColor = viewModel.descriptionTextColor

        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = image

        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(R.string.localizable.refresh(), for: .normal)
        button.addTarget(self, action: #selector(retry), for: .touchUpInside)

        let stackView = [
            imageView,
            titleLabel,
        ].asStackView(axis: .vertical, spacing: 30, alignment: .center)
        stackView.translatesAutoresizingMaskIntoConstraints = false

        if onRetry != nil {
            stackView.addArrangedSubview(button)
        }

        addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            button.widthAnchor.constraint(equalToConstant: 180),
        ])
    }

    @objc func retry() {
        onRetry?()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension TransactionsEmptyView: StatefulPlaceholderView {
    func placeholderViewInsets() -> UIEdgeInsets {
        return insets
    }
}
