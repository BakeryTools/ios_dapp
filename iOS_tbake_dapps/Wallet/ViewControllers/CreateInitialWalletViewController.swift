// Copyright © 2019 Stormbird PTE. LTD.

import UIKit

protocol CreateInitialWalletViewControllerDelegate: AnyObject {
    func didTapCreateWallet(inViewController viewController: CreateInitialWalletViewController)
    func didTapWatchWallet(inViewController viewController: CreateInitialWalletViewController)
    func didTapImportWallet(inViewController viewController: CreateInitialWalletViewController)
}

class CreateInitialWalletViewController: UIViewController {
    private let keystore: Keystore
    private var viewModel = CreateInitialViewModel()
    private let analyticsCoordinator: AnalyticsCoordinator
    private let roundedBackground = RoundedBackground()
    private let subtitleLabel = UILabel()
    private let imageView = UIImageView()
    private let backgroundImage = UIImageView()
    private let createWalletButtonBar = ButtonsBar(configuration: .brown(buttons: 1))
    private let buttonsBar = ButtonsBar(configuration: .white(buttons: 1))

    private var imageViewDimension: CGFloat {
        return screenWidth/2
    }
    private var topMarginOfImageView: CGFloat {
        if ScreenChecker().isNarrowScreen {
            return 100
        } else {
            return 170
        }
    }

    weak var delegate: CreateInitialWalletViewControllerDelegate?

    init(keystore: Keystore, analyticsCoordinator: AnalyticsCoordinator) {
        self.keystore = keystore
        self.analyticsCoordinator = analyticsCoordinator
        
        super.init(nibName: nil, bundle: nil)

        self.roundedBackground.translatesAutoresizingMaskIntoConstraints = false
        
        self.view.addSubview(self.roundedBackground)

        self.imageView.contentMode = .scaleAspectFill
        self.imageView.translatesAutoresizingMaskIntoConstraints = false
        
        self.roundedBackground.addSubview(self.imageView)
        
        self.backgroundImage.contentMode = .scaleAspectFill
        self.backgroundImage.translatesAutoresizingMaskIntoConstraints = false
        
        self.roundedBackground.addSubview(self.backgroundImage)
        
        self.subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        self.roundedBackground.addSubview(self.subtitleLabel)

        let footerBar = UIView()
        footerBar.translatesAutoresizingMaskIntoConstraints = false
        footerBar.backgroundColor = .clear
        
        self.roundedBackground.addSubview(footerBar)
        
        let buttonStackView = [
            self.createWalletButtonBar,
            .spacer(height: 15),
            self.buttonsBar,
            .spacer(height: 15),
        ].asStackView(axis: .vertical)
        
        buttonStackView.translatesAutoresizingMaskIntoConstraints = false
        footerBar.addSubview(buttonStackView)

        NSLayoutConstraint.activate([
            self.imageView.heightAnchor.constraint(equalToConstant: self.imageViewDimension),
            self.imageView.widthAnchor.constraint(equalToConstant: self.imageViewDimension),
            self.imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 0),
            self.imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -125),
            self.imageView.bottomAnchor.constraint(equalTo: self.subtitleLabel.topAnchor, constant: 0),
            
            self.subtitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 25),
            self.subtitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -25),

            self.createWalletButtonBar.heightAnchor.constraint(equalToConstant: ButtonsBar.buttonsHeight),
            
            buttonStackView.leadingAnchor.constraint(equalTo: footerBar.leadingAnchor),
            buttonStackView.trailingAnchor.constraint(equalTo: footerBar.trailingAnchor),
            buttonStackView.topAnchor.constraint(equalTo: footerBar.topAnchor),
            buttonStackView.bottomAnchor.constraint(equalTo: footerBar.bottomAnchor),
            
            self.buttonsBar.heightAnchor.constraint(equalToConstant: ButtonsBar.buttonsHeight),

            footerBar.topAnchor.constraint(greaterThanOrEqualTo: self.subtitleLabel.bottomAnchor, constant: 15),
            footerBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            footerBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            footerBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            self.backgroundImage.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            self.backgroundImage.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            self.backgroundImage.topAnchor.constraint(equalTo: view.topAnchor),
            self.backgroundImage.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            self.roundedBackground.createConstraintsWithContainer(view: view),
        ])
    }

    override func viewWillAppear(_ animated: Bool) {
        print("CreateInitialWalletViewController")
    }
    
    deinit {
        #if DEBUG
        print("🌍🌍🌍 Deinit CreateInitialWalletViewController 🌍🌍🌍")
        #endif
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure() {
        view.backgroundColor = Colors.appBackground
        
        self.subtitleLabel.textAlignment = .center
        self.subtitleLabel.textColor = viewModel.subtitleColor
        self.subtitleLabel.font = viewModel.subtitleFont
        self.subtitleLabel.text = viewModel.subtitle

        self.imageView.image = viewModel.imageViewImage
        self.backgroundImage.image = UIImage(named: "background_img")

        self.createWalletButtonBar.configure()
        let createWalletButton = self.createWalletButtonBar.buttons[0]
        createWalletButton.setTitle(viewModel.createButtonTitle, for: .normal)
        createWalletButton.addTarget(self, action: #selector(self.createWallet), for: .touchUpInside)

        self.buttonsBar.configure()
        let importButton = self.buttonsBar.buttons[0]
        importButton.setTitle(viewModel.importButtonTitle, for: .normal)
        importButton.addTarget(self, action: #selector(self.importWallet), for: .touchUpInside)
    }

    @objc private func createWallet() {
        self.delegate?.didTapCreateWallet(inViewController: self)
    }

    @objc private func importWallet() {
        self.delegate?.didTapImportWallet(inViewController: self)
    }
}
