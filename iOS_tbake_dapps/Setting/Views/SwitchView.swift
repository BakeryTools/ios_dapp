//
//  SwitchView.swift
//  AlphaWallet
//
//  Created by Vladyslav Shepitko on 11.06.2021.
//

import UIKit

protocol SwitchViewDelegate: class {
    func toggledTo(_ newValue: Bool, headerView: SwitchView)
}

struct SwitchViewViewModel {
    var backgroundColor = Colors.appWhite
    var textColor = R.color.black()
    var font = Fonts.regular(size: 17)

    var text: String
    var isOn: Bool

    init(text: String, isOn: Bool) {
        self.text = text
        self.isOn = isOn
    }
}

class SwitchView: UIView {
    private let label = UILabel()
    private let toggle = UISwitch()

    var isOn: Bool {
        toggle.isOn
    }

    weak var delegate: SwitchViewDelegate?

    override init(frame: CGRect) {
        super.init(frame: CGRect())

        toggle.addTarget(self, action: #selector(toggled), for: .valueChanged)

        let stackView = [label, .spacer(), toggle].asStackView(axis: .horizontal, alignment: .center)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.topAnchor.constraint(lessThanOrEqualTo: topAnchor),
            stackView.bottomAnchor.constraint(greaterThanOrEqualTo: bottomAnchor),
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            heightAnchor.constraint(equalToConstant: 40)
        ])
    }

    required init?(coder aDecoder: NSCoder) {
        return nil
    }

    func configure(viewModel: SwitchViewViewModel) {
        backgroundColor = viewModel.backgroundColor

        label.backgroundColor = viewModel.backgroundColor
        label.textColor = viewModel.textColor
        label.font = viewModel.font
        label.text = viewModel.text

        toggle.isOn = viewModel.isOn
    }

    @objc private func toggled() {
        delegate?.toggledTo(toggle.isOn, headerView: self)
    }
}
