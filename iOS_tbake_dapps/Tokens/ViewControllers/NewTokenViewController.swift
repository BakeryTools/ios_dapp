// Copyright SIX DAY LLC. All rights reserved.

import Foundation
import UIKit

protocol NewTokenViewControllerDelegate: AnyObject {
    func didAddToken(token: ERCToken, in viewController: NewTokenViewController)
    func didAddAddress(address: TBakeWallet.Address, in viewController: NewTokenViewController)
    func didTapChangeServer(in viewController: NewTokenViewController)
    func openQRCode(in controller: NewTokenViewController)
    func didClose(viewController: NewTokenViewController)
}

enum RPCServerOrAuto: Hashable {
    case auto
    case server(RPCServer)

    var displayName: String {
        switch self {
        case .auto:
            return R.string.localizable.detectingServerAutomatically()
        case .server(let server):
            return server.displayName
        }
    }

    var name: String {
        switch self {
        case .auto:
            return R.string.localizable.detectingServerAutomaticallyButtonTitle()
        case .server(let server):
            return server.name
        }
    }
}

enum NewTokenInitialState {
    case address(TBakeWallet.Address)
    case empty

    var addressStringValue: String {
        switch self {
        case .address(let address):
            return address.eip55String
        default:
            return String()
        }
    }
}

class NewTokenViewController: UIViewController {
    @IBOutlet weak var contractAddressLbl: UILabel!
    @IBOutlet weak var contractAddressTextField: UITextField!
    @IBOutlet weak var contractAddressErrorLbl: UILabel!
    
    @IBOutlet weak var symbolLbl: UILabel!
    @IBOutlet weak var symbolTextField: UITextField!
    @IBOutlet weak var symbolErrorLbl: UILabel!
    
    @IBOutlet weak var decimalLbl: UILabel!
    @IBOutlet weak var decimalTextField: UITextField!
    @IBOutlet weak var decimalErrorLbl: UILabel!
    
    @IBOutlet weak var nameLbl: UILabel!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var nameErrorLbl: UILabel!
    
    @IBOutlet weak var submitBtn: UIButton!
    
    private var viewModel = NewTokenViewModel()
    private var tokenType: TokenType? = nil {
        didSet {
            updateSaveButtonBasedOnTokenTypeDetected()
        }
    }
//    private let addressTextField = AddressTextField()
    private let changeServerButton = UIButton()
    private var scrollViewBottomAnchorConstraint: NSLayoutConstraint!
    private var shouldFireDetectionWhenAppear: Bool
    private var initialStates: String?
    
    var server: RPCServerOrAuto
    weak var delegate: NewTokenViewControllerDelegate?

    init(server: RPCServerOrAuto, initialState: NewTokenInitialState) {
        self.server = server
        switch initialState {
        case .address:
            shouldFireDetectionWhenAppear = true
        case .empty:
            shouldFireDetectionWhenAppear = false
        }
        super.init(nibName: nil, bundle: nil)

        self.initialStates = initialState.addressStringValue
        self.configure()
    }
    
// swiftlint:enable function_body_length
    override func viewDidLoad() {
        super.viewDidLoad()
        print("NewTokenViewController")
        
        self.setupNavigationBar()
        self.setupTextField()
        self.setupBtn()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if self.shouldFireDetectionWhenAppear {
            self.shouldFireDetectionWhenAppear = false
            self.updateContractValue(value: self.contractAddressTextField.text?.trimmed ?? "")
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if isMovingFromParent || isBeingDismissed {
            delegate?.didClose(viewController: self)
        }
    }
    
    private func setupNavigationBar() {
        self.changeServerButton.setTitleColor(Colors.navigationButtonTintColor, for: .normal)
        self.changeServerButton.addTarget(self, action: #selector(changeServerAction(_:)), for: .touchUpInside)
        self.navigationItem.rightBarButtonItem = .init(customView: self.changeServerButton)
    }
    
    private func setupTextField() {
        self.contractAddressTextField.delegate = self
        self.symbolTextField.delegate = self
        self.decimalTextField.delegate = self
        self.nameTextField.delegate = self
        
        self.contractAddressTextField.layer.borderWidth = 0.8
        self.contractAddressTextField.layer.borderColor = Colors.borderColor.cgColor
        self.contractAddressTextField.layer.cornerRadius = Metrics.CornerRadius.textbox
        
        self.symbolTextField.layer.borderWidth = 0.8
        self.symbolTextField.layer.borderColor = Colors.borderColor.cgColor
        self.symbolTextField.layer.cornerRadius = Metrics.CornerRadius.textbox
        
        self.decimalTextField.layer.borderWidth = 0.8
        self.decimalTextField.layer.borderColor = Colors.borderColor.cgColor
        self.decimalTextField.layer.cornerRadius = Metrics.CornerRadius.textbox
        
        self.nameTextField.layer.borderWidth = 0.8
        self.nameTextField.layer.borderColor = Colors.borderColor.cgColor
        self.nameTextField.layer.cornerRadius = Metrics.CornerRadius.textbox
        
        self.contractAddressTextField.text = self.initialStates
        self.contractAddressTextField.rightViewMode = .always
        self.contractAddressTextField.rightView = self.makeRecipientRightView()
        self.contractAddressLbl.text = viewModel.addressLabel
        self.symbolLbl.text = viewModel.symbolLabel
        self.decimalLbl.text = viewModel.decimalsLabel
        self.nameLbl.text = viewModel.nameLabel
    }
    
    private func setupBtn() {
        self.submitBtn.layer.cornerRadius = 8.0
        self.submitBtn.setTitle(R.string.localizable.done(), for: .normal)
        self.submitBtn.addTarget(self, action: #selector(addToken), for: .touchUpInside)
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

    public func configure() {
        self.title = viewModel.title

        self.updateChangeServer(title: server.name)
    }

    private func updateSaveButtonBasedOnTokenTypeDetected() {
        if tokenType == nil {
            self.submitBtn.isEnabled = false
            self.submitBtn.backgroundColor = Colors.buttonDisabledColor
            self.submitBtn.setTitle(R.string.localizable.detectingTokenTypeTitle(), for: .normal)
        } else {
            self.submitBtn.isEnabled = true
            self.submitBtn.backgroundColor = Colors.tbakeDarkBrown
            self.submitBtn.setTitle(R.string.localizable.done(), for: .normal)
        }
    }

    public func updateSymbolValue(_ symbol: String) {
        self.symbolTextField.text = symbol
    }

    public func updateNameValue(_ name: String) {
        self.nameTextField.text = name
    }

    public func updateDecimalsValue(_ decimals: UInt8) {
        self.decimalTextField.text = String(decimals)
    }

    public func updateForm(forTokenType tokenType: TokenType) {
        self.tokenType = tokenType
    }
    
    private func validate() -> Bool {
        
        self.contractAddressErrorLbl.isHidden = true
        self.symbolErrorLbl.isHidden = true
        self.decimalErrorLbl.isHidden = true
        self.nameErrorLbl.isHidden = true
        
        if self.contractAddressTextField.text.isEmpty {
            self.contractAddressErrorLbl.isHidden = false
            self.contractAddressErrorLbl.text = "Please enter contract address"
            return false
        }
        
        if self.symbolTextField.text.isEmpty {
            self.symbolErrorLbl.isHidden = false
            self.symbolErrorLbl.text = "Please enter token symbol"
            return false
        }
        
        if self.decimalTextField.text.isEmpty {
            self.decimalErrorLbl.isHidden = false
            self.decimalErrorLbl.text = "Please enter token decimal"
            return false
        }
        
//        if let tokenType = self.tokenType {
//            switch tokenType {
//            case .nativeCryptocurrency, .erc20:
//                if self.decimalTextField.text.isEmpty {
//                    self.decimalErrorLbl.isHidden = false
//                    self.decimalErrorLbl.text = "Please enter token decimal"
//                    return false
//                }
//            case .erc721, .erc875, .erc721ForTickets:
//                return true
//            }
//        } else {
//            return false
//        }

        if self.nameTextField.text.isEmpty {
            self.nameErrorLbl.isHidden = false
            self.nameErrorLbl.text = "Please enter token name"
            return false
        }

        return true
    }

    @objc func addToken() {
        guard validate() else { return }
        let server: RPCServer
        switch self.server {
        case .auto:
            self.contractAddressErrorLbl.isHidden = false
            self.contractAddressErrorLbl.text = Errors.invalidAddress.errorDescription
            return
        case .server(let chosenServer):
            server = chosenServer
        }

        let contract = self.contractAddressTextField.text ?? ""
        let name = self.nameTextField.text ?? ""
        let symbol = self.symbolTextField.text ?? ""
        let decimals = Int(self.decimalTextField.text ?? "0") ?? 0
        guard let tokenType = self.tokenType else { return }
        //TODO looks wrong to mention ERC875TokenBalance specifically
        var balance: [String] = viewModel.ERC875TokenBalance

        guard let address = TBakeWallet.Address(string: contract) else {
            self.contractAddressErrorLbl.isHidden = false
            self.contractAddressErrorLbl.text = Errors.invalidAddress.errorDescription
            return
        }

        if balance.isEmpty {
            balance.append("0")
        }

        let ercToken = ERCToken(
            contract: address,
            server: server,
            name: name,
            symbol: symbol,
            decimals: decimals,
            type: tokenType,
            balance: balance
        )

        delegate?.didAddToken(token: ercToken, in: self)
    }

    @objc private func changeServerAction(_ sender: UIView) {
        self.delegate?.didTapChangeServer(in: self)
    }

    private func updateContractValue(value: String) {
        self.tokenType = nil
        self.contractAddressTextField.text = value
        guard let address = TBakeWallet.Address(string: value) else { return }
        self.delegate?.didAddAddress(address: address, in: self)
    }

    struct ValidationError: LocalizedError {
        var msg: String
        var errorDescription: String? {
            return msg
        }
    }

    func redetectToken() {
        let contract = self.contractAddressTextField.text?.trimmed ?? ""
        if let contract = TBakeWallet.Address(string: contract) {
            updateContractValue(value: contract.eip55String)
        }
    }
    
    func didScanQRCode(_ result: String) {
        guard let result = QRCodeValueParser.from(string: result) else { return }
        switch result {
        case .address(let address):
            updateContractValue(value: address.eip55String)
        case .eip681:
            break
        }
    }

    private func updateChangeServer(title: String) {
        self.changeServerButton.setTitle(title, for: .normal)
        //Needs to re-create navigationItem.rightBarButtonItem to update button width for new title's length
        self.navigationItem.rightBarButtonItem = .init(customView: changeServerButton)
    }
    
    @objc func openReader(_ sender: UIButton) {
        self.delegate?.openQRCode(in: self)
    }
    
    @objc func doPaste(_ sender: UIButton) {
        if let value = UIPasteboard.general.string?.trimmed {
            self.updateContractValue(value: value)
            self.contractAddressErrorLbl.isHidden = true
            self.view.endEditing(true)
        }
    }
}

extension NewTokenViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case self.contractAddressTextField:
            self.symbolTextField.becomeFirstResponder()
        case self.symbolTextField:
            self.decimalTextField.becomeFirstResponder()
        case self.decimalTextField:
            self.nameTextField.becomeFirstResponder()
        default:
            self.view.endEditing(true)
        }
        
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == self.contractAddressTextField {
            let string = ((textField.text ?? "") as NSString).replacingCharacters(in: range, with: string)
            if CryptoAddressValidator.isValidAddress(string) {
                self.updateContractValue(value: string)
            }
        }
        
        return true
    }
}
