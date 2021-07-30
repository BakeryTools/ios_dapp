// Copyright © 2018 Stormbird PTE. LTD.

import UIKit
import WalletCore

protocol ImportWalletViewControllerDelegate: AnyObject {
    func didImportAccount(account: Wallet, in viewController: ImportWalletViewController)
    func openQRCode(in controller: ImportWalletViewController)
}

class ImportWalletViewController: UIViewController {
    struct ValidationError: LocalizedError {
        var msg: String
        var errorDescription: String? {
            return msg
        }
    }

    private static let mnemonicSuggestionsBarHeight: CGFloat = ScreenChecker().isNarrowScreen ? 40 : 60

    private let keystore: Keystore
    private let analyticsCoordinator: AnalyticsCoordinator
    private let viewModel = ImportWalletViewModel()
    //We don't actually use the rounded corner here, but it's a useful "content" view here
    private let roundedBackground = RoundedBackground()
    private let backgroundImage = UIImageView()
    private let scrollView = UIScrollView()
    private let mnemonicCountLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .right
        return label
    }()
    private lazy var mnemonicTextView: TextView = {
        let textView = TextView()
        textView.label.translatesAutoresizingMaskIntoConstraints = false
        textView.delegate = self
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.returnKeyType = .done
        textView.textView.autocorrectionType = .no
        textView.textView.autocapitalizationType = .none

        return textView
    }()

    private lazy var mnemonicControlsStackView: UIStackView = {
        let row2 = [mnemonicTextView.statusLabel, mnemonicCountLabel].asStackView()
        row2.translatesAutoresizingMaskIntoConstraints = false
        let mnemonicControlsStackView = [
            mnemonicTextView.label,
            .spacer(height: 4),
            mnemonicTextView,
            .spacer(height: 4),
            row2
        ].asStackView(axis: .vertical, distribution: .fill)
        mnemonicControlsStackView.translatesAutoresizingMaskIntoConstraints = false

        return mnemonicControlsStackView
    }()

    private lazy var importSeedDescriptionLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.isHidden = false
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    private let buttonsBar = ButtonsBar(configuration: .brown(buttons: 1))
    private var footerBottomConstraint: NSLayoutConstraint!
    private lazy var keyboardChecker = KeyboardChecker(self)
    private var mnemonicSuggestions: [String] = .init() {
        didSet {
            mnemonicSuggestionsCollectionView.reloadData()
        }
    }

    private let mnemonicSuggestionsCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.estimatedItemSize = CGSize(width: 140, height: ScreenChecker().isNarrowScreen ? 30 : 40)
        layout.scrollDirection = .horizontal

        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.contentInset = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        cv.register(SeedPhraseSuggestionViewCell.self)

        return cv
    }()

    private var mnemonicInput: [String] {
        mnemonicInputString.split(separator: " ").map { String($0) }
    }

    private var mnemonicInputString: String {
        mnemonicTextView.value.lowercased()
    }

    weak var delegate: ImportWalletViewControllerDelegate?

    init(keystore: Keystore, analyticsCoordinator: AnalyticsCoordinator) {
        self.keystore = keystore
        self.analyticsCoordinator = analyticsCoordinator

        super.init(nibName: nil, bundle: nil)

        self.title = viewModel.title
        
        self.backgroundImage.contentMode = .scaleAspectFill
        self.backgroundImage.translatesAutoresizingMaskIntoConstraints = false
        self.roundedBackground.addSubview(self.backgroundImage)
        
        roundedBackground.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(roundedBackground)

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        roundedBackground.addSubview(scrollView)

//        tabBar.delegate = self
//        tabBar.translatesAutoresizingMaskIntoConstraints = false
//        view.addSubview(tabBar)

        let stackView = [
//            tabBar,
            .spacer(height: ScreenChecker().isNarrowScreen ? 5 : 10),
            mnemonicControlsStackView
        ].asStackView(axis: .vertical)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stackView)

        roundedBackground.addSubview(importSeedDescriptionLabel)

        mnemonicSuggestionsCollectionView.frame = .init(x: 0, y: 0, width: 0, height: ImportWalletViewController.mnemonicSuggestionsBarHeight)

        let footerBar = UIView()
        footerBar.translatesAutoresizingMaskIntoConstraints = false
        footerBar.backgroundColor = .clear
        roundedBackground.addSubview(footerBar)

        footerBar.addSubview(buttonsBar)

        let heightThatFitsPrivateKeyNicely = CGFloat(ScreenChecker().isNarrowScreen ? 80 : 100)

        footerBottomConstraint = footerBar.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        footerBottomConstraint.constant = -UIApplication.shared.bottomSafeAreaHeight
        keyboardChecker.constraint = footerBottomConstraint

        let labelButtonInset: CGFloat = ScreenChecker().isNarrowScreen ? 10 : 20

        NSLayoutConstraint.activate([
            mnemonicTextView.heightAnchor.constraint(equalToConstant: heightThatFitsPrivateKeyNicely),

            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 15),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -15),
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            
            self.backgroundImage.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            self.backgroundImage.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            self.backgroundImage.topAnchor.constraint(equalTo: view.topAnchor),
            self.backgroundImage.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            importSeedDescriptionLabel.leadingAnchor.constraint(equalTo: footerBar.leadingAnchor, constant: 30),
            importSeedDescriptionLabel.trailingAnchor.constraint(equalTo: footerBar.trailingAnchor, constant: -30),
            importSeedDescriptionLabel.bottomAnchor.constraint(equalTo: footerBar.topAnchor, constant: -labelButtonInset),

            footerBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            footerBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            footerBar.heightAnchor.constraint(equalToConstant: ButtonsBar.buttonsHeight),
            footerBottomConstraint,

            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: footerBar.topAnchor),

        ] + roundedBackground.createConstraintsWithContainer(view: view) + buttonsBar.anchorsConstraint(to: footerBar))

        configure()
        showMnemonicControlsOnly()

        navigationItem.rightBarButtonItem = UIBarButtonItem(image: R.image.qr_code_icon(), style: .done, target: self, action: #selector(openReader))

        if UserDefaults.standard.bool(forKey: "FASTLANE_SNAPSHOT") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.demo()
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.backgroundImage.image = UIImage(named: "background_img")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        print("ImportWalletViewController")
        super.viewWillAppear(animated)
        //Because we want the filter to look like it's a part of the navigation bar
        navigationController?.navigationBar.shadowImage = UIImage()
        keyboardChecker.viewWillAppear()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        keyboardChecker.viewWillDisappear()
    }

    private func showCorrectTab() {
        self.showMnemonicControlsOnly()
    }

    func configure() {
        view.backgroundColor = viewModel.backgroundColor

        mnemonicTextView.configureOnce()
        mnemonicTextView.label.text = viewModel.mnemonicLabel

        mnemonicCountLabel.font = DataEntry.Font.label
        mnemonicCountLabel.textColor = DataEntry.Color.label
        mnemonicCountLabel.text = "\(mnemonicInput.count) Words"

        mnemonicSuggestionsCollectionView.backgroundColor = .white
        mnemonicSuggestionsCollectionView.backgroundColor = R.color.mike()
        mnemonicSuggestionsCollectionView.showsHorizontalScrollIndicator = false
        mnemonicSuggestionsCollectionView.delegate = self
        mnemonicSuggestionsCollectionView.dataSource = self

        importSeedDescriptionLabel.attributedText = viewModel.importSeedAttributedText

        buttonsBar.configure()
        let importButton = buttonsBar.buttons[0]
        importButton.addTarget(self, action: #selector(importWallet), for: .touchUpInside)
        configureImportButtonTitle(R.string.localizable.importWalletImportButtonTitle())
    }

    private func configureImportButtonTitle(_ title: String) {
        let importButton = buttonsBar.buttons[0]
        importButton.setTitle(title, for: .normal)
    }

    func didImport(account: Wallet) {
        delegate?.didImportAccount(account: account, in: self)
    }

    ///Returns true only if valid
    private func validate() -> Bool {
        return validateMnemonic()
    }

    ///Returns true only if valid
    private func validateMnemonic() -> Bool {
        mnemonicTextView.errorState = .none

        if let validationError = MnemonicLengthRule().isValid(value: mnemonicInputString) {
            mnemonicTextView.errorState = .error(validationError.msg)

            return false
        }
        if let validationError = MnemonicInWordListRule().isValid(value: mnemonicInputString) {
            mnemonicTextView.errorState = .error(validationError.msg)
            return false
        }
        return true
    }

    @objc func importWallet() {
        guard validate() else { return }
        
        displayLoading(text: R.string.localizable.importWalletImportingIndicatorLabelTitle(), animated: false)

        let importTypeOptional: ImportType? = {
            return .mnemonic(words: mnemonicInput, password: "")
        }()
        
        guard let importType = importTypeOptional else { return }

        keystore.importWallet(type: importType) { [weak self] result in
            guard let strongSelf = self else { return }
            strongSelf.hideLoading(animated: false)
            switch result {
            case .success(let account):
                strongSelf.didImport(account: account)
            case .failure(let error):
                strongSelf.displayError(error: error)
            }
        }
    }

    @objc func demo() {
        //Used for taking screenshots to the App Store by snapshot
        let demoWallet = Wallet(type: .watch(TBakeWallet.Address(string: "0xD663bE6b87A992C5245F054D32C7f5e99f5aCc47")!))
        delegate?.didImportAccount(account: demoWallet, in: self)
    }

    @objc private func openReader() {
        delegate?.openQRCode(in: self)
    }

    func setValueForCurrentField(string: String) {
        mnemonicTextView.value = string

        showCorrectTab()
    }

    required init?(coder aDecoder: NSCoder) {
        return nil
    }

    private func showMnemonicControlsOnly() {
        mnemonicControlsStackView.isHidden = false
        importSeedDescriptionLabel.isHidden = false
        let importButton = buttonsBar.buttons[0]
        importButton.isEnabled = !mnemonicTextView.value.isEmpty
        mnemonicTextView.textView.inputAccessoryView = mnemonicSuggestionsCollectionView
        mnemonicTextView.textView.reloadInputViews()
    }

//    private func showKeystoreControlsOnly() {
//        mnemonicControlsStackView.isHidden = true
//        keystoreJSONControlsStackView.isHidden = false
//        privateKeyControlsStackView.isHidden = true
//        watchControlsStackView.isHidden = true
//        configureImportButtonTitle(R.string.localizable.importWalletImportButtonTitle())
//        importKeystoreJsonFromCloudButton.isHidden = false
//        importSeedDescriptionLabel.isHidden = true
//        let importButton = buttonsBar.buttons[0]
//        importButton.isEnabled = !keystoreJSONTextView.value.isEmpty && !passwordTextField.value.isEmpty
//        mnemonicTextView.textView.inputAccessoryView = nil
//        mnemonicTextView.textView.reloadInputViews()
//    }
//
//    private func showPrivateKeyControlsOnly() {
//        mnemonicControlsStackView.isHidden = true
//        keystoreJSONControlsStackView.isHidden = true
//        privateKeyControlsStackView.isHidden = false
//        watchControlsStackView.isHidden = true
//        configureImportButtonTitle(R.string.localizable.importWalletImportButtonTitle())
//        importKeystoreJsonFromCloudButton.isHidden = true
//        importSeedDescriptionLabel.isHidden = true
//        let importButton = buttonsBar.buttons[0]
//        importButton.isEnabled = !privateKeyTextView.value.isEmpty
//        mnemonicTextView.textView.inputAccessoryView = nil
//        mnemonicTextView.textView.reloadInputViews()
//    }
//
//    private func showWatchControlsOnly() {
//        mnemonicControlsStackView.isHidden = true
//        keystoreJSONControlsStackView.isHidden = true
//        privateKeyControlsStackView.isHidden = true
//        watchControlsStackView.isHidden = false
//        configureImportButtonTitle(R.string.localizable.walletWatchButtonTitle())
//        importKeystoreJsonFromCloudButton.isHidden = true
//        importSeedDescriptionLabel.isHidden = true
//        let importButton = buttonsBar.buttons[0]
//        importButton.isEnabled = !watchAddressTextField.value.isEmpty
//        mnemonicTextView.textView.inputAccessoryView = nil
//        mnemonicTextView.textView.reloadInputViews()
//    }

    private func moveFocusToTextEntryField(after textInput: UIView) {
        view.endEditing(true)
    }
}
// swiftlint:enable type_body_length

extension ImportWalletViewController: TextFieldDelegate {

    func didScanQRCode(_ result: String) {
        setValueForCurrentField(string: result)
    }

    func shouldReturn(in textField: TextField) -> Bool {
        moveFocusToTextEntryField(after: textField)
        return false
    }

    func doneButtonTapped(for textField: TextField) {
        view.endEditing(true)
    }

    func nextButtonTapped(for textField: TextField) {
        moveFocusToTextEntryField(after: textField)
    }

    func shouldChangeCharacters(inRange range: NSRange, replacementString string: String, for textField: TextField) -> Bool {
        //Just easier to dispatch
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.showCorrectTab()
        }
        return true
    }
}

extension ImportWalletViewController: TextViewDelegate {
    func shouldReturn(in textView: TextView) -> Bool {
        moveFocusToTextEntryField(after: textView)
        return false
    }

    func doneButtonTapped(for textView: TextView) {
        view.endEditing(true)
    }

    func nextButtonTapped(for textView: TextView) {
        moveFocusToTextEntryField(after: textView)
    }

    func didChange(inTextView textView: TextView) {
        showCorrectTab()
        guard textView == mnemonicTextView else { return }
        mnemonicCountLabel.text = "\(mnemonicInput.count) words"
        if let lastMnemonic = mnemonicInput.last {
            mnemonicSuggestions = HDWallet.getSuggestions(forWord: String(lastMnemonic))
        } else {
            mnemonicSuggestions = .init()
        }
    }
}

extension ImportWalletViewController: AddressTextFieldDelegate {
    func displayError(error: Error, for textField: AddressTextField) {
        textField.errorState = .error(error.prettyError)
    }

    func openQRCodeReader(for textField: AddressTextField) {
        openReader()
    }

    func didPaste(in textField: AddressTextField) {
        view.endEditing(true)
        showCorrectTab()
    }

    func shouldReturn(in textField: AddressTextField) -> Bool {
        moveFocusToTextEntryField(after: textField)
        return false
    }

    func didChange(to string: String, in textField: AddressTextField) {
        showCorrectTab()
    }
}

extension ImportWalletViewController: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        mnemonicSuggestions.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: SeedPhraseSuggestionViewCell = collectionView.dequeueReusableCell(for: indexPath)
        cell.configure(word: mnemonicSuggestions[indexPath.row])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let words = replacingLastWord(of: mnemonicInput, with: "\(mnemonicSuggestions[indexPath.row]) ")
        mnemonicTextView.value = words.joined(separator: " ")
    }

    private func replacingLastWord(of words: [String], with replacement: String) -> [String] {
        var words = words
        words.removeLast()
        words.append(replacement)
        return words
    }
}
