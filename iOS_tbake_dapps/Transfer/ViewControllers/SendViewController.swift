// Copyright SIX DAY LLC. All rights reserved.
// Copyright © 2018 Stormbird PTE. LTD.

import Foundation
import UIKit
import JSONRPCKit
import APIKit
import PromiseKit
import BigInt
import MBProgressHUD

protocol SendViewControllerDelegate: AnyObject, CanOpenURL {
    func didPressConfirm(transaction: UnconfirmedTransaction, in viewController: SendViewController, amount: String, shortValue: String?)
    func lookup(contract: TBakeWallet.Address, in viewController: SendViewController, completion: @escaping (ContractData) -> Void)
    func openQRCode(in controller: SendViewController)
}

class SendViewController: UIViewController {
    @IBOutlet weak var recipientAddressLbl: UILabel!
    @IBOutlet weak var recipientAddressTextField: UITextField!
    @IBOutlet weak var recipientAddressErrorLbl: UILabel!
    
    @IBOutlet weak var amountLbl: UILabel!
    @IBOutlet weak var amountTextField: UITextField!
    @IBOutlet weak var amountErrorLbl: UILabel!
    @IBOutlet weak var sendBtn: UIButton!
    
    private var viewModel: SendViewModel
    private var balanceViewModel: BalanceBaseViewModel?
    private let session: WalletSession
    private let account: TBakeWallet.Address
    private let ethPrice: Subscribable<Double>
    private let assetDefinitionStore: AssetDefinitionStore
    private var currentSubscribableKeyForNativeCryptoCurrencyBalance: Subscribable<BalanceBaseViewModel>.SubscribableKey?
    private var currentSubscribableKeyForNativeCryptoCurrencyPrice: Subscribable<Double>.SubscribableKey?

    //We use weak link to make sure that token alert will be deallocated by close button tapping.
    //We storing link to make sure that only one alert is displaying on the screen.
    private weak var invalidTokenAlert: UIViewController?
    weak var delegate: SendViewControllerDelegate?

    var transactionType: TransactionType {
        return viewModel.transactionType
    }

    let storage: TokensDataStore
    @objc private (set) dynamic var isAllFunds: Bool = false
    private var observation: NSKeyValueObservation!

    init(
            session: WalletSession,
            storage: TokensDataStore,
            account: TBakeWallet.Address,
            transactionType: TransactionType,
            cryptoPrice: Subscribable<Double>,
            assetDefinitionStore: AssetDefinitionStore
    ) {
        self.session = session
        self.account = account
        self.storage = storage
        self.ethPrice = cryptoPrice
        self.assetDefinitionStore = assetDefinitionStore
        self.viewModel = .init(transactionType: transactionType, session: session, storage: storage)

        super.init(nibName: nil, bundle: nil)

        configureBalanceViewModel()

        storage.updatePrices()

//        observation = observe(\.isAllFunds, options: [.initial, .new]) { [weak self] _, _ in
//            guard let strongSelf = self else { return }

//            strongSelf.amountTextField.isAllFunds = strongSelf.isAllFunds
//        }
    }
// swiftlint:enable function_body_length

    override func viewDidLoad() {
        super.viewDidLoad()
        print("SendViewController")
        
        self.activateRecipientView()
        
        self.recipientAddressTextField.delegate = self
        self.amountTextField.delegate = self
        
        self.recipientAddressTextField.layer.cornerRadius = Metrics.CornerRadius.textbox
        self.amountTextField.layer.cornerRadius = Metrics.CornerRadius.textbox
        
        self.recipientAddressLbl.text = viewModel.recipientsAddress
        self.recipientAddressTextField.rightViewMode = .always
        self.recipientAddressTextField.rightView = makeRecipientRightView()
        self.recipientAddressTextField.layer.borderWidth = 0.8
        self.recipientAddressTextField.layer.borderColor = Colors.borderColor.cgColor
        self.amountLbl.text = "\(viewModel.amountLbl) (\(viewModel.availableLabelText ?? "(Available: 0"))"
        self.amountTextField.rightViewMode = .always
        self.amountTextField.rightView = makeAmountRightView()
        self.amountTextField.layer.borderWidth = 0.8
        self.amountTextField.layer.borderColor = Colors.borderColor.cgColor
        
        self.sendBtn.layer.cornerRadius = 8.0
        self.sendBtn.addTarget(self, action: #selector(send), for: .touchUpInside)
        
        switch transactionType {
        case .nativeCryptocurrency(_, let destination, let amount):
            self.recipientAddressTextField.text = destination?.stringValue ?? ""
            if let amount = amount {
                self.amountTextField.text = EtherNumberFormatter.full.string(from: amount, units: .ether)
            } else {
                //do nothing, especially not set it to a default BigInt() / 0
            }
        case .ERC20Token(_, let destination, let amount):
            self.recipientAddressTextField.text = destination?.stringValue ?? ""
            self.amountTextField.text = amount ?? ""
        case .ERC875Token, .ERC875TokenOrder, .ERC721Token, .ERC721ForTicketToken, .dapp, .tokenScript, .claimPaidErc875MagicLink:
            break
        }
    }

    @objc func closeKeyboard() {
        view.endEditing(true)
    }

    func configure(viewModel: SendViewModel, shouldConfigureBalance: Bool = true) {
        self.viewModel = viewModel
        //Avoids infinite recursion
        if shouldConfigureBalance {
            configureBalanceViewModel()
        }

        updateNavigationTitle()
    }

    private func updateNavigationTitle() {
        self.title = "\(R.string.localizable.send()) \(transactionType.symbol)"
    }
    
    private func makeAmountRightView() -> UIButton {
        let maxButton = Button(size: .normal, style: .borderless)
        maxButton.translatesAutoresizingMaskIntoConstraints = false
        maxButton.setTitle(R.string.localizable.sendMax(), for: .normal)
        maxButton.addTarget(self, action: #selector(self.allFundsSelected(_:)), for: .touchUpInside)
        maxButton.titleLabel?.font = DataEntry.Font.accessory
        maxButton.setTitleColor(DataEntry.Color.icon, for: .normal)
        maxButton.backgroundColor = Colors.backgroundClear
        maxButton.tintColor = .none

        return maxButton
    }
    
    private func makeRecipientRightView() -> UIView {
        let scanQRCodeButton = Button(size: .normal, style: .system)
        scanQRCodeButton.translatesAutoresizingMaskIntoConstraints = false
        scanQRCodeButton.setImage(R.image.qr_code_icon(), for: .normal)
        scanQRCodeButton.addTarget(self, action: #selector(self.openReader(_:)), for: .touchUpInside)
        scanQRCodeButton.setBackgroundColor(.clear, forState: .normal)
        //NOTE: Fix clipped shadow on textField (iPhone 5S)
        scanQRCodeButton.clipsToBounds = false
        scanQRCodeButton.layer.masksToBounds = false
        
        let pasteButton = Button(size: .normal, style: .borderless)
        pasteButton.translatesAutoresizingMaskIntoConstraints = false
        pasteButton.setTitle(R.string.localizable.sendPasteButtonTitle(), for: .normal)
        pasteButton.addTarget(self, action: #selector(self.doPaste(_:)), for: .touchUpInside)
        pasteButton.titleLabel?.font = DataEntry.Font.accessory
        pasteButton.setTitleColor(DataEntry.Color.icon, for: .normal)
        pasteButton.backgroundColor = Colors.backgroundClear
        pasteButton.tintColor = .none
        pasteButton.setBackgroundColor(.clear, forState: .normal)
        
        let stackView = [
            pasteButton,
            .spacerWidth(3),
            scanQRCodeButton
        ].asStackView(axis: .horizontal)

        let targetAddressRightView = [stackView].asStackView(distribution: .fill)
        targetAddressRightView.clipsToBounds = false
        targetAddressRightView.layer.masksToBounds = false
        targetAddressRightView.backgroundColor = .clear
        //As of iOS 13, we need to constrain the width of `rightView`
        let rightViewFittingSize = targetAddressRightView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        NSLayoutConstraint.activate([
//            targetAddressRightView.heightAnchor.constraint(equalToConstant: ScreenChecker().isNarrowScreen ? 30 : 50),
            targetAddressRightView.widthAnchor.constraint(equalToConstant: rightViewFittingSize.width),
        ])
        targetAddressRightView.translatesAutoresizingMaskIntoConstraints = false

        return targetAddressRightView
    }
    
    @objc func openReader(_ sender: UIButton) {
        self.delegate?.openQRCode(in: self)
    }
    
    @objc func doPaste(_ sender: UIButton) {
        if let value = UIPasteboard.general.string?.trimmed {
            self.recipientAddressTextField.text = value
            self.recipientAddressErrorLbl.isHidden = true
        }
    }

    @objc func allFundsSelected(_ sender: UIButton) {
        switch transactionType {
        case .nativeCryptocurrency:
            guard let ethCost = allFundsFormattedValues else { return }
            isAllFunds = true
            self.amountTextField.text = "\(ethCost.allFundsFullValue ?? 0)"
//            amountTextField.set(ethCost: ethCost.allFundsFullValue, shortEthCost: ethCost.allFundsShortValue, useFormatting: false)
        case .ERC20Token:
            guard let ethCost = allFundsFormattedValues else { return }
            isAllFunds = true
            self.amountTextField.text = "\(ethCost.allFundsFullValue ?? 0)"
//            amountTextField.set(ethCost: ethCost.allFundsFullValue, shortEthCost: ethCost.allFundsShortValue, useFormatting: false)
        case .dapp, .ERC721ForTicketToken, .ERC721Token, .ERC875Token, .ERC875TokenOrder, .tokenScript, .claimPaidErc875MagicLink:
            break
        }
    }

    private var allFundsFormattedValues: (allFundsFullValue: NSDecimalNumber?, allFundsShortValue: String)? {
        switch transactionType {
        case .nativeCryptocurrency:
            guard let balance = session.balance else { return nil }

            let fullValue = EtherNumberFormatter.plain.string(from: balance.value, units: .ether).droppedTrailingZeros
            let shortValue = EtherNumberFormatter.shortPlain.string(from: balance.value, units: .ether).droppedTrailingZeros

            return (fullValue.optionalDecimalValue, shortValue)
        case .ERC20Token(let token, _, _):
            let fullValue = EtherNumberFormatter.plain.string(from: token.valueBigInt, decimals: token.decimals).droppedTrailingZeros
            let shortValue = EtherNumberFormatter.shortPlain.string(from: token.valueBigInt, decimals: token.decimals).droppedTrailingZeros

            return (fullValue.optionalDecimalValue, shortValue)
        case .dapp, .ERC721ForTicketToken, .ERC721Token, .ERC875Token, .ERC875TokenOrder, .tokenScript, .claimPaidErc875MagicLink:
            return nil
        }
    }
    
    private func doValidation() -> Bool {
        self.recipientAddressErrorLbl.isHidden = true
        self.amountErrorLbl.isHidden = true
        
        if self.recipientAddressTextField.text?.isEmpty ?? false {
            self.recipientAddressErrorLbl.isHidden = false
            self.recipientAddressErrorLbl.text = viewModel.recipientErrorEmptyLbl
            
            return false
        } else if self.amountTextField.text?.isEmpty ?? false {
            self.amountErrorLbl.isHidden = false
            self.amountErrorLbl.text = viewModel.amountErrorEmptyLbl
            
            return false
        }
        
        return true
    }

    @objc private func send() {
        if doValidation() {
            let input = self.recipientAddressTextField.text?.trimmed ?? ""
            self.recipientAddressErrorLbl.isHidden = true
            self.amountErrorLbl.isHidden = true
            let checkIfGreaterThanZero: Bool
            switch transactionType {
            case .nativeCryptocurrency, .dapp, .tokenScript, .claimPaidErc875MagicLink:
                checkIfGreaterThanZero = false
            case .ERC20Token, .ERC875Token, .ERC875TokenOrder, .ERC721Token, .ERC721ForTicketToken:
                checkIfGreaterThanZero = true
            }

            guard let value = viewModel.validatedAmount(value: self.amountTextField.text ?? "0", checkIfGreaterThanZero: checkIfGreaterThanZero) else {
                self.amountErrorLbl.isHidden = false
                self.amountErrorLbl.text = viewModel.amountErrorLbl
                return
            }
            guard let recipient = TBakeWallet.Address(string: input) else {
                self.recipientAddressErrorLbl.isHidden = false
                self.recipientAddressErrorLbl.text = viewModel.recipientErrorLbl
                return
            }

            let transaction = UnconfirmedTransaction(
                    transactionType: transactionType,
                    value: value,
                    recipient: recipient,
                    contract: transactionType.contractForFungibleSend,
                    data: nil
            )

            delegate?.didPressConfirm(transaction: transaction, in: self, amount: self.amountTextField.text ?? "0", shortValue: shortValueForAllFunds)
        }
    }

    var shortValueForAllFunds: String? {
        return isAllFunds ? allFundsFormattedValues?.allFundsShortValue : .none
    }
    
    func activateRecipientView() {
        self.recipientAddressTextField.becomeFirstResponder()
    }

    func activateAmountView(address: String) {
        self.recipientAddressTextField.text = address
        self.amountTextField.becomeFirstResponder()
    }

    required init?(coder aDecoder: NSCoder) {
        return nil
    }

    private func configureBalanceViewModel() {
        currentSubscribableKeyForNativeCryptoCurrencyBalance.flatMap { session.balanceViewModel.unsubscribe($0) }
        currentSubscribableKeyForNativeCryptoCurrencyPrice.flatMap { ethPrice.unsubscribe($0) }
        switch transactionType {
        case .nativeCryptocurrency(_, let recipient, let amount):
            currentSubscribableKeyForNativeCryptoCurrencyBalance = session.balanceViewModel.subscribe { [weak self] viewModel in
                guard let celf = self else { return }
                guard celf.storage.token(forContract: celf.viewModel.transactionType.contract) != nil else { return }
                celf.configureFor(contract: celf.viewModel.transactionType.contract, recipient: recipient, amount: amount, shouldConfigureBalance: false)
            }
            session.refresh(.ethBalance)
        case .ERC20Token(let token, let recipient, let amount):
            let amount = amount.flatMap { EtherNumberFormatter.plain.number(from: $0, decimals: token.decimals) }
            configureFor(contract: viewModel.transactionType.contract, recipient: recipient, amount: amount, shouldConfigureBalance: false)
        case .ERC875Token, .ERC875TokenOrder, .ERC721Token, .ERC721ForTicketToken, .dapp, .tokenScript, .claimPaidErc875MagicLink:
            break
        }
    }

    func didScanQRCode(_ result: String) {
        guard let result = QRCodeValueParser.from(string: result) else { return }
        switch result {
        case .address(let recipient):
            guard let tokenObject = storage.token(forContract: viewModel.transactionType.contract) else { return }
            let amountAsIntWithDecimals = EtherNumberFormatter.plain.number(from: self.amountTextField.text ?? "0", decimals: tokenObject.decimals)
            configureFor(contract: transactionType.contract, recipient: .address(recipient), amount: amountAsIntWithDecimals)
            activateAmountView(address: recipient.eip55String)
        case .eip681(let protocolName, let address, let functionName, let params):
            checkAndFillEIP681Details(protocolName: protocolName, address: address, functionName: functionName, params: params)
        }
    }

    private func showInvalidToken() {
        guard invalidTokenAlert == nil else { return }

        invalidTokenAlert = UIAlertController.alert(
            message: R.string.localizable.sendInvalidToken(),
            alertButtonTitles: [R.string.localizable.oK()],
            alertButtonStyles: [.cancel],
            viewController: self
        )
    }

    private func checkAndFillEIP681Details(protocolName: String, address: AddressOrEnsName, functionName: String?, params: [String: String]) {
        //TODO error display on returns
        Eip681Parser(protocolName: protocolName, address: address, functionName: functionName, params: params).parse().done { result in
            guard let (contract: contract, optionalServer, recipient, maybeScientificAmountString) = result.parameters else { return }
            let amount = self.convertMaybeScientificAmountToBigInt(maybeScientificAmountString)
            //For user-safety and simpler implementation, we ignore the link if it is for a different chain
            if let server = optionalServer {
                guard self.session.server == server else { return }
            }

            if self.storage.token(forContract: contract) != nil {
                //For user-safety and simpler implementation, we ignore the link if it is for a different chain
                self.configureFor(contract: contract, recipient: recipient, amount: amount)
                self.activateAmountView(address: address.stringValue)
            } else {
                self.delegate?.lookup(contract: contract, in: self) { data in
                    switch data {
                    case .name, .symbol, .balance, .decimals:
                        break
                    case .nonFungibleTokenComplete:
                        self.showInvalidToken()
                    case .fungibleTokenComplete(let name, let symbol, let decimals):
                        //TODO update fetching to retrieve balance too so we can display the correct balance in the view controller
                        let token = ERCToken(
                                contract: contract,
                                server: self.storage.server,
                                name: name,
                                symbol: symbol,
                                decimals: Int(decimals),
                                type: .erc20,
                                balance: ["0"]
                        )
                        self.storage.addCustom(token: token)
                        self.configureFor(contract: contract, recipient: recipient, amount: amount)
                        self.activateAmountView(address: address.stringValue)
                    case .delegateTokenComplete:
                        self.showInvalidToken()
                    case .failed:
                        break
                    }
                }
            }
        }.cauterize()
    }

    //This function is required because BigInt.init(String) doesn't handle scientific notation
    private func convertMaybeScientificAmountToBigInt(_ maybeScientificAmountString: String) -> BigInt? {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.usesGroupingSeparator = false
        let amountString = numberFormatter.number(from: maybeScientificAmountString).flatMap { numberFormatter.string(from: $0) }
        return amountString.flatMap { BigInt($0) }
    }

    private func configureFor(contract: TBakeWallet.Address, recipient: AddressOrEnsName?, amount: BigInt?, shouldConfigureBalance: Bool = true) {
        guard let tokenObject = storage.token(forContract: contract) else { return }
        let amount = amount.flatMap { EtherNumberFormatter.plain.string(from: $0, decimals: tokenObject.decimals) }
        let transactionType: TransactionType
        if let amount = amount, amount != "0" {
            transactionType = TransactionType(token: tokenObject, recipient: recipient, amount: amount)
        } else {
            switch viewModel.transactionType {
            case .nativeCryptocurrency(_, _, let amount):
                transactionType = TransactionType(token: tokenObject, recipient: recipient, amount: amount.flatMap { EtherNumberFormatter().string(from: $0, units: .ether) })
            case .ERC20Token(_, _, let amount):
                transactionType = TransactionType(token: tokenObject, recipient: recipient, amount: amount)
            case .ERC875Token, .ERC875TokenOrder, .ERC721Token, .ERC721ForTicketToken, .dapp, .tokenScript, .claimPaidErc875MagicLink:
                transactionType = TransactionType(token: tokenObject, recipient: recipient, amount: nil)
            }
        }

        configure(viewModel: .init(transactionType: transactionType, session: session, storage: storage), shouldConfigureBalance: shouldConfigureBalance)
    }
}
// swiftlint:enable type_body_length

extension SendViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case self.amountTextField:
            self.view.endEditing(true)
        default:
            self.amountTextField.becomeFirstResponder()
        }
        
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == self.amountTextField {
            self.amountErrorLbl.isHidden = true

            guard viewModel.validatedAmount(value: textField.text ?? "0", checkIfGreaterThanZero: false) != nil else {
                self.amountErrorLbl.isHidden = false
                self.amountErrorLbl.text = viewModel.amountErrorLbl
                return true
            }
        }
        
        return true
    }

}

