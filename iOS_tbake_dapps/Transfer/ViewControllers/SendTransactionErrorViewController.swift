// Copyright © 2021 Stormbird PTE. LTD.

import UIKit

protocol SendTransactionErrorViewControllerDelegate: AnyObject {
    func rectifyErrorButtonTapped(error: SendTransactionNotRetryableError, inController controller: SendTransactionErrorViewController)
    func linkTapped(_ url: URL, forError error: SendTransactionNotRetryableError, inController controller: SendTransactionErrorViewController)
    func controllerDismiss(_ controller: SendTransactionErrorViewController)
}

class SendTransactionErrorViewController: UIViewController {
    
    @IBOutlet weak var parentView: UIView!
    
    @IBOutlet weak var titleLbl: UILabel!
    @IBOutlet weak var descriptionLbl: UILabel!
    
    @IBOutlet weak var confirmBtn: UIButton!
    @IBOutlet weak var cancelBtn: UIButton!
    
    private let server: RPCServer
    private let error: SendTransactionNotRetryableError
    private lazy var viewModel = SendTransactionErrorViewModel(server: server, error: error)
 
    private var allowPresentationAnimation: Bool = true
    private var allowDismissalAnimation: Bool = true

    weak var delegate: SendTransactionErrorViewControllerDelegate?

    init(server: RPCServer, error: SendTransactionNotRetryableError) {
        self.server = server
        self.error = error
        super.init(nibName: nil, bundle: nil)

    }

    override func viewDidLoad() {
        super.viewDidLoad()
        print("SendTransactionErrorViewController")
        
        self.setupView()
        self.setupBtn()

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
        
        self.titleLbl.text = viewModel.title
        self.descriptionLbl.text = viewModel.description
    }
    
    private func setupBtn() {
        self.confirmBtn.layer.cornerRadius = 8.0
        self.cancelBtn.addTarget(self, action: #selector(doDismiss(_:)), for: .touchUpInside)
        self.confirmBtn.addTarget(self, action: #selector(rectifyErrorButtonTapped(_:)), for: .touchUpInside)
    }

    @objc private func linkButtonTapped() {
        if let url = viewModel.linkUrl {
            delegate?.linkTapped(url, forError: error, inController: self)
        } else {
            assertImpossibleCodePath(message: "Should only show link button if there's a URl")
        }
    }
    
    @objc private func doDismiss(_ sender: UIButton) {
        self.delegate?.controllerDismiss(self)
    }

    @objc private func rectifyErrorButtonTapped(_ sender: UIButton) {
        self.delegate?.rectifyErrorButtonTapped(error: error, inController: self)
    }

    required init?(coder aDecoder: NSCoder) {
        return nil
    }
}
