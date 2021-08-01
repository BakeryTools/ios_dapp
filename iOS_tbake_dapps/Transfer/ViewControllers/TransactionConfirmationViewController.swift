// Copyright © 2020 Stormbird PTE. LTD.

import BigInt
import Foundation
import UIKit
import Result

protocol TransactionConfirmationViewControllerDelegate: AnyObject {
    func controller(_ controller: TransactionConfirmationViewController, continueButtonTapped sender: UIButton)
    func controllerDidTapEdit(_ controller: TransactionConfirmationViewController)
    func didClose(in controller: TransactionConfirmationViewController)
}

class TransactionConfirmationViewController: UIViewController {
    enum State {
        case ready
        case pending
        case done(withError: Bool)
    }

    @IBOutlet weak var parentView: UIView!
    
    @IBOutlet weak var cancelBtn: UIButton!
    @IBOutlet weak var editGasBtn: UIButton!
    @IBOutlet weak var confirmBtn: UIButton!
    
    @IBOutlet weak var transactionTitle: UILabel!
    
    @IBOutlet weak var balanceTitleLbl: UILabel!
    @IBOutlet weak var oldBalanceLbl: UILabel!
    @IBOutlet weak var newBalanceLbl: UILabel!
    
    @IBOutlet weak var networkLbl: UILabel!
    @IBOutlet weak var networkImgView: UIImageView!
    @IBOutlet weak var networkTypeLbl: UILabel!
    
    @IBOutlet weak var gasFeeLbl: UILabel!
    @IBOutlet weak var gasFeeTypeLbl: UILabel!
    @IBOutlet weak var gasFeeDataLbl: UILabel!
    
    @IBOutlet weak var recipientLbl: UILabel!
    @IBOutlet weak var recipientAddressLbl: UILabel!
    
    @IBOutlet weak var amountLbl: UILabel!
    @IBOutlet weak var amountDataLbl: UILabel!
    
    @IBOutlet weak var balanceStackView: UIStackView!
    @IBOutlet weak var networkStackView: UIStackView!
    @IBOutlet weak var gasStackView: UIStackView!
    @IBOutlet weak var recipientStackView: UIStackView!
    @IBOutlet weak var amountStackView: UIStackView!
    
    private var viewModel: TransactionConfirmationViewModel
    private var timerToReenableConfirmButton: Timer?

    private var allowPresentationAnimation = true
    private var canBeConfirmed = true
    private var allowDismissalAnimation = true
    var canBeDismissed = true
    
    weak var delegate: TransactionConfirmationViewControllerDelegate?
    
    init(viewModel: TransactionConfirmationViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)

        switch viewModel {
        case .dappOrWalletConnectTransaction(let dappTransactionViewModel):
            dappTransactionViewModel.ethPrice.subscribe { cryptoToDollarRate in
                //guard let strongSelf = self else { return }
                dappTransactionViewModel.cryptoToDollarRate = cryptoToDollarRate
                //strongSelf.generateSubviews()
            }
        case .tokenScriptTransaction(let tokenScriptTransactionViewModel):
            tokenScriptTransactionViewModel.ethPrice.subscribe { cryptoToDollarRate in
                //guard let strongSelf = self else { return }
                tokenScriptTransactionViewModel.cryptoToDollarRate = cryptoToDollarRate
                //strongSelf.generateSubviews()
            }
        case .sendFungiblesTransaction(let sendFungiblesViewModel):
            sendFungiblesViewModel.recipientResolver.resolve {
                //guard let strongSelf = self else { return }
                //strongSelf.generateSubviews()
            }

            switch sendFungiblesViewModel.transactionType {
            case .nativeCryptocurrency:
                sendFungiblesViewModel.session.balanceViewModel.subscribe { balanceBaseViewModel in
                    //guard let strongSelf = self else { return }
                    sendFungiblesViewModel.updateBalance(.nativeCryptocurrency(balanceViewModel: balanceBaseViewModel))
                    //strongSelf.generateSubviews()
                }
                sendFungiblesViewModel.ethPrice.subscribe { cryptoToDollarRate in
                    //guard let strongSelf = self else { return }
                    sendFungiblesViewModel.cryptoToDollarRate = cryptoToDollarRate
                    //strongSelf.generateSubviews()
                }
                sendFungiblesViewModel.session.refresh(.ethBalance)
            case .ERC20Token(let token, _, _):
                sendFungiblesViewModel.updateBalance(.erc20(token: token))
                sendFungiblesViewModel.ethPrice.subscribe { cryptoToDollarRate in
                    //guard let strongSelf = self else { return }
                    sendFungiblesViewModel.cryptoToDollarRate = cryptoToDollarRate
                    //strongSelf.generateSubviews()
                }
            case .ERC875Token, .ERC875TokenOrder, .ERC721Token, .ERC721ForTicketToken, .dapp, .tokenScript, .claimPaidErc875MagicLink:
                sendFungiblesViewModel.ethPrice.subscribe { cryptoToDollarRate in
                    //guard let strongSelf = self else { return }
                    sendFungiblesViewModel.cryptoToDollarRate = cryptoToDollarRate
                    //strongSelf.generateSubviews()
                }
            }
        case .sendNftTransaction(let sendNftViewModel):
            sendNftViewModel.recipientResolver.resolve {
                //guard let strongSelf = self else { return }
                //strongSelf.generateSubviews()
            }
            sendNftViewModel.ethPrice.subscribe { cryptoToDollarRate in
                //guard let strongSelf = self else { return }
                sendNftViewModel.cryptoToDollarRate = cryptoToDollarRate
                //strongSelf.generateSubviews()
            }
        case .claimPaidErc875MagicLink(let claimPaidErc875MagicLinkViewModel):
            claimPaidErc875MagicLinkViewModel.ethPrice.subscribe { cryptoToDollarRate in
                //guard let strongSelf = self else { return }
                claimPaidErc875MagicLinkViewModel.cryptoToDollarRate = cryptoToDollarRate
                //strongSelf.generateSubviews()
            }
        case .speedupTransaction(let speedupTransactionViewModel):
            speedupTransactionViewModel.ethPrice.subscribe { cryptoToDollarRate in
                //guard let strongSelf = self else { return }
                speedupTransactionViewModel.cryptoToDollarRate = cryptoToDollarRate
                //strongSelf.generateSubviews()
            }
        case .cancelTransaction(let cancelTransactionViewModel):
            cancelTransactionViewModel.ethPrice.subscribe { cryptoToDollarRate in
                //guard let strongSelf = self else { return }
                cancelTransactionViewModel.cryptoToDollarRate = cryptoToDollarRate
                //strongSelf.generateSubviews()
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        return nil
    }

    // swiftlint:enable function_body_length
    override func viewDidLoad() {
        super.viewDidLoad()
        print("TransactionConfirmationViewController")
        self.setupView()
        self.setupBtn()
        self.generateSubviews()
        self.set(state: .ready){}
        self.configure(for: viewModel)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if let navigationController = navigationController {
            navigationController.setNavigationBarHidden(true, animated: false)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if let navigationController = navigationController {
            navigationController.setNavigationBarHidden(false, animated: false)
        }
    }
    
    private func setupView() {
        self.parentView.layer.cornerRadius = 15
        
        self.transactionTitle.text = viewModel.navigationTitle
    }
    
    private func setupBtn() {
        self.confirmBtn.layer.cornerRadius = 8.0
        self.cancelBtn.addTarget(self, action: #selector(doDismiss(_:)), for: .touchUpInside)
        self.editGasBtn.addTarget(self, action: #selector(doEditGas(_:)), for: .touchUpInside)
        self.confirmBtn.addTarget(self, action: #selector(confirmButtonTapped(_:)), for: .touchUpInside)
    }

    func set(state: State, completion: (() -> Void)) {
        switch state {
        case .ready:
            self.confirmBtn.setTitle(viewModel.title, for: .normal)
        case .pending:
            self.confirmBtn.setTitle(viewModel.titlePending, for: .normal)
        case .done:
            self.confirmBtn.setTitle(viewModel.title, for: .normal)
            completion()
        }
    }
    
    // MARK:- Action Function
    @objc private func doEditGas(_ sender: UIButton) {
        self.delegate?.controllerDidTapEdit(self)
    }

    @objc private func doDismiss(_ sender: UIButton) {
        guard canBeDismissed else { return }
        self.delegate?.didClose(in: self)
    }

    func reloadView() {
        generateSubviews()
    }

    func reloadViewWithGasChanges() {
        canBeConfirmed = false
        reloadView()
        createTimerToRestoreConfirmButton()
    }

    //NOTE: we need to recalculate all funds value to send according to updated gas estimates, nativecrypto only
    func reloadViewWithCurrentBalanceValue() {
        switch viewModel {
        case .dappOrWalletConnectTransaction, .tokenScriptTransaction, .speedupTransaction, .cancelTransaction:
            break
        case .sendFungiblesTransaction(let sendFungiblesViewModel):
            switch sendFungiblesViewModel.transactionType {
            case .nativeCryptocurrency:
                guard let balanceBaseViewModel = sendFungiblesViewModel.session.balanceViewModel.value else { return }

                sendFungiblesViewModel.updateBalance(.nativeCryptocurrency(balanceViewModel: balanceBaseViewModel))
            case .ERC20Token, .ERC875Token, .ERC875TokenOrder, .ERC721Token, .ERC721ForTicketToken, .dapp, .tokenScript, .claimPaidErc875MagicLink:
                break
            }
        case .sendNftTransaction, .claimPaidErc875MagicLink:
            break
        }
    }

    private func createTimerToRestoreConfirmButton() {
        timerToReenableConfirmButton?.invalidate()
        let gap = TimeInterval(0.3)
        timerToReenableConfirmButton = Timer.scheduledTimer(withTimeInterval: gap, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            self.canBeConfirmed = true
        }
    }

    private func configure(for viewModel: TransactionConfirmationViewModel) {
        self.title = viewModel.title
    }

    @objc func confirmButtonTapped(_ sender: UIButton) {
        guard canBeConfirmed else { return }
        self.delegate?.controller(self, continueButtonTapped: sender)
    }
}

extension TransactionConfirmationViewController {
    // swiftlint:disable function_body_length
    private func generateSubviews() {
        switch viewModel {
        case .dappOrWalletConnectTransaction(let viewModel): //segala transaksi dlm dapp
            for section in viewModel.sections { //(_, section) in viewModel.sections.enumerated()
                switch section {
                case .gas:
                    self.gasStackView.isHidden = false
                    self.gasFeeLbl.text = section.title
                    self.gasFeeTypeLbl.text = viewModel.getGasTitle()
                    self.gasFeeDataLbl.text = viewModel.getGasData()
                    self.editGasBtn.setTitle(R.string.localizable.editButtonTitle(), for: .normal)
                    self.editGasBtn.isHidden = false
                case .amount:
                    self.amountStackView.isHidden = false
                    self.amountLbl.text = section.title
                    self.amountDataLbl.text = viewModel.getAmount()
                case .network:
                    self.networkStackView.isHidden = false
                    self.networkLbl.text = section.title
                    self.networkImgView.image = viewModel.getIconNetwork()
                    self.networkTypeLbl.text = viewModel.getNetwork()
                case .function:
                    break
                }
            }
        case .tokenScriptTransaction(let viewModel):
            for section in viewModel.sections {
                switch section {
                case .gas:
                    self.gasStackView.isHidden = false
                    self.gasFeeLbl.text = section.title
                    self.gasFeeTypeLbl.text = viewModel.getGasTitle()
                    self.gasFeeDataLbl.text = viewModel.getGasData()
                    self.editGasBtn.setTitle(R.string.localizable.editButtonTitle(), for: .normal)
                    self.editGasBtn.isHidden = false
                case .function:
                    break
                case .contract:
                    break
                case .amount:
                    self.amountStackView.isHidden = false
                    self.amountLbl.text = section.title
                    self.amountDataLbl.text = viewModel.getAmount()
                case .network:
                    self.networkStackView.isHidden = false
                    self.networkLbl.text = section.title
                    self.networkImgView.image = viewModel.getIconNetwork()
                    self.networkTypeLbl.text = viewModel.getNetwork()
                }
            }
        case .sendFungiblesTransaction(let viewModel): // send token
            for section in viewModel.sections {
                switch section {
                case .recipient:
                    self.recipientStackView.isHidden = false
                    self.recipientLbl.text = section.title
                    self.recipientAddressLbl.text = viewModel.getRecipient()
                case .gas:
                    self.gasStackView.isHidden = false
                    self.gasFeeLbl.text = section.title
                    self.gasFeeTypeLbl.text = viewModel.getGasTitle()
                    self.gasFeeDataLbl.text = viewModel.getGasData()
                    self.editGasBtn.setTitle(R.string.localizable.editButtonTitle(), for: .normal)
                    self.editGasBtn.isHidden = false
                case .amount:
                    self.amountStackView.isHidden = false
                    self.amountLbl.text = section.title
                    self.amountDataLbl.text = viewModel.getAmount()
                case .balance:
                    self.balanceStackView.isHidden = false
                    self.balanceTitleLbl.text = section.title
                    self.oldBalanceLbl.text = viewModel.getOldBalance()
                    self.newBalanceLbl.text = viewModel.getNewBalance()
                case .network:
                    break
                }
            }
        case .sendNftTransaction(let viewModel):
            for section in viewModel.sections {
                switch section {
                case .recipient:
                    break
                case .gas:
                    break
                case .tokenId, .network:
                    break
                }
            }
        case .claimPaidErc875MagicLink(let viewModel):
            for section in viewModel.sections {
                switch section {
                case .gas:
                    break
                case .amount, .numberOfTokens, .network:
                    break
                }
            }
        case .speedupTransaction(let viewModel):
            for section in viewModel.sections {
                switch section {
                case .gas:
                    break
                case .description:
                    break
                }
            }
        case .cancelTransaction(let viewModel):
            for section in viewModel.sections {
                switch section {
                case .gas:
                    break
                case .description:
                    break
                }
            }
        }
    }
    // swiftlint:enable function_body_length
}

extension TransactionConfirmationViewController: TransactionConfirmationHeaderViewDelegate {

    func headerView(_ header: TransactionConfirmationHeaderView, shouldHideChildren section: Int, index: Int) -> Bool {
        return true
    }

    func headerView(_ header: TransactionConfirmationHeaderView, shouldShowChildren section: Int, index: Int) -> Bool {
        switch viewModel {
        case .dappOrWalletConnectTransaction, .claimPaidErc875MagicLink, .tokenScriptTransaction, .speedupTransaction, .cancelTransaction:
            return true
        case .sendFungiblesTransaction(let viewModel):
            switch viewModel.sections[section] {
            case .recipient, .network:
                return !viewModel.isSubviewsHidden(section: section, row: index)
            case .gas, .amount, .balance:
                return true
            }
        case .sendNftTransaction(let viewModel):
            switch viewModel.sections[section] {
            case .recipient, .network:
                //NOTE: Here we need to make sure that this view is available to display
                return !viewModel.isSubviewsHidden(section: section, row: index)
            case .gas, .tokenId:
                return true
            }
        }
    }

    func headerView(_ header: TransactionConfirmationHeaderView, openStateChanged section: Int) {
        switch viewModel.showHideSection(section) {
        case .show:
            header.expand()
        case .hide:
            header.collapse()
        }

        UIView.animate(withDuration: 0.35) {
            self.view.layoutIfNeeded()
        }
    }

    func headerView(_ header: TransactionConfirmationHeaderView, tappedSection section: Int) {
        delegate?.controllerDidTapEdit(self)
    }
} 
