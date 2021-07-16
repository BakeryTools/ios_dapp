// Copyright © 2018 Stormbird PTE. LTD.

import Foundation
import UIKit

protocol TokenViewControllerHeaderViewDelegate: class {
    func didPressViewContractWebPage(forContract contract: AlphaWallet.Address, inHeaderView: TokenViewControllerHeaderView)
    func didShowHideMarketPrice(inHeaderView: TokenViewControllerHeaderView)
}

class TokenViewControllerHeaderView: UIView {
    private let contract: AlphaWallet.Address
    private let recentTransactionsLabel = UILabel()
    private let recentTransactionsLabelBorders = (top: UIView(), bottom: UIView())
    private let spacers = (beforeTokenScriptFileStatus: UIView.spacer(height: DataEntry.Metric.SendHeader.topSpacerHeight), ())

    let sendHeaderView = SendHeaderView()
    weak var delegate: TokenViewControllerHeaderViewDelegate?

    init(contract: AlphaWallet.Address) {
        self.contract = contract
        super.init(frame: .zero)

        sendHeaderView.delegate = self

        let recentTransactionsLabelHolder = UIView()
        recentTransactionsLabelHolder.backgroundColor = Colors.backgroundClear
        recentTransactionsLabel.translatesAutoresizingMaskIntoConstraints = false
        recentTransactionsLabelHolder.addSubview(recentTransactionsLabel)

        let labelStackView = [
            .spacer(height: 10),
            recentTransactionsLabelHolder,
            .spacer(height: 10),
        ].asStackView(axis: .vertical)
        labelStackView.translatesAutoresizingMaskIntoConstraints = false
        
        let stackView = [
            spacers.beforeTokenScriptFileStatus,
            sendHeaderView,
            recentTransactionsLabelBorders.top,
            labelStackView,
            recentTransactionsLabelBorders.bottom,
            .spacer(height: 7),
        ].asStackView(axis: .vertical)
        
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)

        NSLayoutConstraint.activate([
            recentTransactionsLabelBorders.top.heightAnchor.constraint(equalToConstant: 1),
            recentTransactionsLabelBorders.bottom.heightAnchor.constraint(equalToConstant: 1),
            
            recentTransactionsLabel.topAnchor.constraint(equalTo: recentTransactionsLabelHolder.topAnchor),
            recentTransactionsLabel.bottomAnchor.constraint(equalTo: recentTransactionsLabelHolder.bottomAnchor),
            recentTransactionsLabel.leadingAnchor.constraint(equalTo: recentTransactionsLabelHolder.leadingAnchor, constant: 15),

            stackView.anchorsConstraint(to: self),
        ])

        configure()
    }

    required init?(coder aDecoder: NSCoder) {
        return nil
    }

    private func configure() {
        recentTransactionsLabel.textColor = Screen.TokenCard.Color.title
        recentTransactionsLabel.font = Screen.TokenCard.Font.blockChainName
        recentTransactionsLabel.text = R.string.localizable.recentTransactions()

        recentTransactionsLabelBorders.top.backgroundColor = Colors.lightGray
        recentTransactionsLabelBorders.bottom.backgroundColor = Colors.lightGray
    }
}

extension TokenViewControllerHeaderView: SendHeaderViewDelegate {
    func didPressViewContractWebPage(inHeaderView: SendHeaderView) {
        delegate?.didPressViewContractWebPage(forContract: contract, inHeaderView: self)
    }

    func showHideMarketPriceSelected(inHeaderView: SendHeaderView) {
        delegate?.didShowHideMarketPrice(inHeaderView: self)
    }
}
