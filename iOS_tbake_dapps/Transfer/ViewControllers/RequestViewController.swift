// Copyright © 2018 Stormbird PTE. LTD.
import Foundation
import UIKit
import CoreImage
import MBProgressHUD

//Careful to fit in shorter phone like iPhone 5s without needing to scroll
class RequestViewController: UIViewController {
    @IBOutlet weak var titleLbl: UILabel!
    @IBOutlet weak var qrCodeImgView: UIImageView!
    @IBOutlet weak var addressView: UIView!
    @IBOutlet weak var addressLbl: UILabel!
    @IBOutlet weak var copyBtn: UIButton!

	private let viewModel: RequestViewModel

	init(viewModel: RequestViewModel) {
		self.viewModel = viewModel

		super.init(nibName: nil, bundle: nil)
	}
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("RequestViewController")
        
        self.title = R.string.localizable.aSettingsContentsMyWalletAddress()
        
        self.setupView()
        self.setupLbl()
        self.setupImgView()
        self.setupBtn()
    }
    
    private func setupView() {
        self.addressView.layer.cornerRadius = self.addressView.frame.size.height / 2
    }

    private func setupLbl(){
        self.titleLbl.text = self.viewModel.instructionText
        self.addressLbl.text = self.viewModel.myAddressText
    }
    
    private func setupImgView(){
        self.qrCodeImgView.layer.cornerRadius = 8.0
        self.generateImageQRCode()
    }
    
    private func setupBtn() {
        self.copyBtn.addTarget(self, action: #selector(self.doCopy(_:)), for: .touchUpInside)
    }

    private func showFeedback() {
        UINotificationFeedbackGenerator.show(feedbackType: .success)
    }

    func generateQRCode(from string: String) -> UIImage? {
        return string.toQRCode()
    }
    
	func generateImageQRCode() {
        let string = self.viewModel.myAddressText
        let image = self.generateQRCode(from: string)
        self.qrCodeImgView.image = image
	}
    
    @objc func doCopy(_ sender: UIButton) {
		UIPasteboard.general.string = viewModel.myAddressText

		let hud = MBProgressHUD.showAdded(to: view, animated: true)
		hud.mode = .text
        hud.label.text = self.viewModel.addressCopiedText
		hud.hide(animated: true, afterDelay: 1.5)

	}
}
