//
//  ChartViewController.swift
//  iOS_tbake_dapps
//
//  Created by Danial on 26/07/2021.
//

import UIKit
import WebKit
import JavaScriptCore

protocol ChartViewControllerDelegate: AnyObject {
    func openPage(url: URL?, forceReload: Bool)
    func didCall(action: DappAction, callbackID: Int, inBrowserViewController viewController: ChartViewController)
}

class ChartViewController: UIViewController {
    @IBOutlet weak var parentView: UIView!
    
    weak var delegate: ChartViewControllerDelegate?
    
    private let account: Wallet
    private let server: RPCServer
    
    private struct Keys {
        static let estimatedProgress = "estimatedProgress"
        static let developerExtrasEnabled = "developerExtrasEnabled"
        static let URL = "URL"
        static let ClientName = "SafeWallet" //Danial
    }

    private lazy var userClient: String = {
        return Keys.ClientName + "/" + (Bundle.main.versionNumber ?? "")
    }()
    
    lazy var config: WKWebViewConfiguration = {
        let config = WKWebViewConfiguration.make(forType: .dappBrowser(server), address: account.address, in: ScriptMessageProxy(delegate: self))
        config.websiteDataStore = WKWebsiteDataStore.default()
        return config
    }()
    
    lazy var webView: WKWebView = {
        let webView = WKWebView(
            frame: .zero,
            configuration: self.config
        )
        webView.allowsBackForwardNavigationGestures = true
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.navigationDelegate = self
        if isDebug {
            webView.configuration.preferences.setValue(true, forKey: Keys.developerExtrasEnabled)
        }
        return webView
    }()
    
    init(account: Wallet, server: RPCServer) {
        self.account = account
        self.server = server
        
        super.init(nibName: nil, bundle: nil)
        
        self.injectUserAgent()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("ChartViewController")
        // Do any additional setup after loading the view.
        self.title = R.string.localizable.chartTabbarItemTitle()
        self.setupWebView()
        self.setupNavigationBar()
    }
    
    func setupNavigationBar() {
        let refreshButton = UIBarButtonItem(image: UIImage(systemName: "arrow.clockwise"), style: .plain, target: self, action: #selector(self.reloadPage))
        refreshButton.tintColor = Colors.tbakeDarkBrown
        self.navigationItem.rightBarButtonItem = refreshButton
    }
    
    func setupWebView() {
        self.webView.navigationDelegate = self
        self.webView.uiDelegate = self
        self.webView.configuration.preferences.javaScriptEnabled = true
        self.webView.isOpaque = false
        self.webView.backgroundColor = UIColor.clear
        
        self.parentView.addSubview(self.webView)
        
        NSLayoutConstraint.activate([
            webView.anchorsConstraint(to: self.parentView),
        ])
    }

    func urlSetup(urlString: String) {
        let urlStrings = urlString == "" ? "https://chart.bakerytools.io" : urlString
        guard let url =  URL(string: urlStrings) else { return }
        let request = URLRequest(url: url)
        
        self.webView.load(request)
    }
    
    func notifyFinish(callbackID: Int, value: Result<DappCallback, DAppError>) {
        let script: String = {
            switch value {
            case .success(let result):
                return "executeCallback(\(callbackID), null, \"\(result.value.object)\")"
            case .failure(let error):
                return "executeCallback(\(callbackID), \"\(error.message)\", null)"
            }
        }()
        webView.evaluateJavaScript(script, completionHandler: nil)
    }
    
    private func injectUserAgent() {
        webView.evaluateJavaScript("navigator.userAgent") { [weak self] result, _ in
            guard let strongSelf = self, let currentUserAgent = result as? String else { return }
            strongSelf.webView.customUserAgent = currentUserAgent + " " + strongSelf.userClient
        }
    }
    
    @objc func reloadPage() {
        self.webView.reload()
    }
}

//MARK:- WKWebview Navigation Delegate
extension ChartViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didStartProvisionalNavigation _: WKNavigation!) {

        UIView.animate(withDuration: 0.33, animations: {
//            self.progressIndicator.alpha = 1.0
        })
    }
    
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Swift.Void) {
        
            if(navigationAction.navigationType == .other) {
                
                if navigationAction.request.url != nil {
                    //do what you need with url
                    //self.delegate?.openURL(url: navigationAction.request.url!)
                }
                decisionHandler(.allow)
            }else{
                decisionHandler(.allow)
            }
    }
    
    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
//        if webView.url?.absoluteString.contains("thank_you") ?? false{
//            UserPrefs.riwayatPesananNeedRefresh.set(1)
//            self.setRightNavigationButton()
//        }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!){
        
        UIView.animate(withDuration: 0.33, animations: {
//            self.progressIndicator.alpha = 0.0
        }, completion: { done in
            //if got loading presented, dismiss
//            self.progressIndicator.isHidden = done
        })
    }
}

//MARK:- WKWebview WKUIDelegate Delegate
extension ChartViewController: WKUIDelegate {
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if let frame = navigationAction.targetFrame,
            frame.isMainFrame {
            return nil
        }
        
        if navigationAction.request.url?.absoluteString.contains("pancakeswap") ?? false {
            if webView.url?.absoluteString == "https://chart.bakerytools.io/token/0x26D6e280F9687c463420908740AE59f712419147" || webView.url?.absoluteString == "https://chart.bakerytools.io/" {
                guard let urlToSwap = URL(string: "https://v1exchange.pancakeswap.finance/#/swap?outputCurrency=0x26D6e280F9687c463420908740AE59f712419147") else { return nil }
                self.delegate?.openPage(url: urlToSwap, forceReload: true)
            } else {
                let tokenAddress = webView.url?.absoluteString.replacingOccurrences(of: "https://chart.bakerytools.io/token/", with: "")
                guard let urlToSwap = URL(string: "https://pancakeswap.finance/swap?outputCurrency=\(tokenAddress ?? "")") else { return nil }
                self.delegate?.openPage(url: urlToSwap, forceReload: true)
            }
        } else {
            self.delegate?.openPage(url: navigationAction.request.url, forceReload: false)
        }
    
        // for _blank target or non-mainFrame target
        
        return nil
    }
    
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let alertController = UIAlertController(title: "Attention", message: message, preferredStyle: .alert)

        alertController.addAction(UIAlertAction(title: "OK", style: .cancel) {_ in
            completionHandler()
        })

        self.present(alertController, animated: true, completion: nil)
    }
    
    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        let alertController = UIAlertController(title: "Delete File", message: message, preferredStyle: .alert)

        alertController.addAction(UIAlertAction(title: "OK", style: .default) {_ in
            completionHandler(true)
        })

        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel)  {_ in
            completionHandler(false)
        })
        
        self.present(alertController, animated: true, completion: nil)
    }
}

//MARK:- WKScriptMessageHandler Delegate
extension ChartViewController: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let command = DappAction.fromMessage(message) else { return }
        let requester = DAppRequester(title: webView.title, url: webView.url)
        let token = TokensDataStore.token(forServer: server)
        let action = DappAction.fromCommand(command, server: server, transactionType: .dapp(token, requester))

        delegate?.didCall(action: action, callbackID: command.id, inBrowserViewController: self)
    }
}

//MARK:- WKScriptMessageHandler class to avoid retain cycle memory
class LeakAvoider : NSObject, WKScriptMessageHandler {
    weak var delegate : WKScriptMessageHandler?
    
    init(delegate: WKScriptMessageHandler) {
        self.delegate = delegate
        super.init()
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        self.delegate?.userContentController(userContentController, didReceive: message)
    }
}
