// Copyright © 2018 Stormbird PTE. LTD.

import UIKit
import Result
import SafariServices
import MBProgressHUD

protocol TransactionViewControllerDelegate: AnyObject, CanOpenURL {
}

class TransactionViewController: UIViewController {
    @IBOutlet weak var titleView: UIView!
    @IBOutlet weak var titleLbl: UILabel!
    @IBOutlet weak var tokenLbl: UILabel!
    
    @IBOutlet weak var fromLbl: UILabel!
    @IBOutlet weak var fromAddressLbl: UILabel!
    @IBOutlet weak var fromCopyBtn: UIButton!
    
    @IBOutlet weak var toLbl: UILabel!
    @IBOutlet weak var toAddressLbl: UILabel!
    @IBOutlet weak var toCopyBtn: UIButton!
    
    @IBOutlet weak var gasLbl: UILabel!
    @IBOutlet weak var gasDataLbl: UILabel!
    
    @IBOutlet weak var confirmationLbl: UILabel!
    @IBOutlet weak var confirmationDataLbl: UILabel!
    
    @IBOutlet weak var transactionLbl: UILabel!
    @IBOutlet weak var transactionAddressLbl: UILabel!
    @IBOutlet weak var transactionCopyBtn: UIButton!
    
    @IBOutlet weak var transactionTimeLbl: UILabel!
    @IBOutlet weak var transactionTimeDataLbl: UILabel!
    
    @IBOutlet weak var blockLbl: UILabel!
    @IBOutlet weak var blockDataLbl: UILabel!
    
    @IBOutlet weak var nonceLbl: UILabel!
    @IBOutlet weak var nonceDataLbl: UILabel!
    
    @IBOutlet weak var viewBinanceExplorerBtn: UIButton!
    
    private let analyticsCoordinator: AnalyticsCoordinator
    private lazy var viewModel: TransactionDetailsViewModel = {
        return .init(
            transactionRow: transactionRow,
            chainState: session.chainState,
            currentWallet: session.account,
            currencyRate: session.balanceCoordinator.currencyRate
        )
    }()
    private let session: WalletSession
    private let transactionRow: TransactionRow

    weak var delegate: TransactionViewControllerDelegate?

    init(analyticsCoordinator: AnalyticsCoordinator, session: WalletSession, transactionRow: TransactionRow, delegate: TransactionViewControllerDelegate?) {
        self.analyticsCoordinator = analyticsCoordinator
        self.session = session
        self.transactionRow = transactionRow
        self.delegate = delegate

        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        return nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("TransactionViewController")
        
        self.title = self.viewModel.title
        
        self.setupRightBarButton()
        self.setupView()
        self.setupLbl()
        self.setupBtn()
    }
    
    private func setupRightBarButton() {
        if self.viewModel.shareAvailable {
            let shareButton = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(self.doShare(_:)))
            shareButton.tintColor = Colors.tbakeDarkBrown
            self.navigationItem.rightBarButtonItem = shareButton
        }
    }

    private func setupView() {
        self.titleView.layer.cornerRadius = 5.0
    }
    
    private func setupLbl() {
        self.titleLbl.text = self.session.server.name
        self.tokenLbl.attributedText = self.viewModel.amountAttributedString
        
        self.fromLbl.text = self.viewModel.fromLabelTitle
        self.fromAddressLbl.text = self.viewModel.from
        
        self.toLbl.text = self.viewModel.toLabelTitle
        self.toAddressLbl.text = self.viewModel.to
        
        self.gasLbl.text = self.viewModel.gasFeeLabelTitle
        self.gasDataLbl.text = self.viewModel.gasFee
        
        self.confirmationLbl.text = self.viewModel.confirmationLabelTitle
        self.confirmationDataLbl.text = self.viewModel.confirmation
        
        self.transactionLbl.text = self.viewModel.transactionIDLabelTitle
        self.transactionAddressLbl.text = self.viewModel.transactionID
        
        self.transactionTimeLbl.text = self.viewModel.createdAtLabelTitle
        self.transactionTimeDataLbl.text = self.viewModel.createdAt
        
        self.blockLbl.text = self.viewModel.blockNumberLabelTitle
        self.blockDataLbl.text = self.viewModel.blockNumber
        
        self.nonceLbl.text = self.viewModel.nonceLabelTitle
        self.nonceDataLbl.text = self.viewModel.nonce
    }
    
    private func setupBtn() {
        self.viewBinanceExplorerBtn.setTitle(self.viewModel.detailsButtonText, for: .normal)
        self.viewBinanceExplorerBtn.addTarget(self, action: #selector(self.doMore(_:)), for: .touchUpInside)
        self.viewBinanceExplorerBtn.layer.cornerRadius = 8.0
        
        self.fromCopyBtn.tag = 1
        self.toCopyBtn.tag = 2
        self.transactionCopyBtn.tag = 3
        
        self.fromCopyBtn.addTarget(self, action: #selector(self.doCopy(_:)), for: .touchUpInside)
        self.toCopyBtn.addTarget(self, action: #selector(self.doCopy(_:)), for: .touchUpInside)
        self.transactionCopyBtn.addTarget(self, action: #selector(self.doCopy(_:)), for: .touchUpInside)
    }
    
    private func showFeedback() {
        UINotificationFeedbackGenerator.show(feedbackType: .success)
    }

    @objc func doCopy(_ sender: UIButton) {
        
        switch sender.tag {
        case 1:
            UIPasteboard.general.string = self.viewModel.from
        case 2:
            UIPasteboard.general.string = self.viewModel.to
        default:
            UIPasteboard.general.string = self.viewModel.transactionID
        }

        let hud = MBProgressHUD.showAdded(to: view, animated: true)
        hud.mode = .text
        hud.label.text = self.viewModel.addressCopiedText
        hud.hide(animated: true, afterDelay: 1.5)

    }

    @objc func doMore(_ sender: UIButton) {
        guard let url = viewModel.detailsURL else { return }
        self.delegate?.didPressOpenWebPage(url, in: self)
    }

    @objc func doShare(_ sender: UIBarButtonItem) {
        guard let item = viewModel.shareItem else { return }
        let activityViewController = UIActivityViewController(
            activityItems: [
                item,
            ],
            applicationActivities: nil
        )
        
        activityViewController.popoverPresentationController?.barButtonItem = sender
        
        DispatchQueue.main.async { self.navigationController?.present(activityViewController, animated: true, completion: nil) }
    }

    @objc func dismiss() {
        self.dismiss(animated: true, completion: nil)
    }
}

// MARK: Analytics
extension TransactionViewController {
    private func logUse() {
        analyticsCoordinator.log(navigation: Analytics.Navigation.explorer, properties: [Analytics.Properties.type.rawValue: Analytics.ExplorerType.transaction.rawValue])
    }
}
