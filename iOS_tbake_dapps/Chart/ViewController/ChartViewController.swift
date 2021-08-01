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
    func underConstruction()
}

class ChartViewController: UIViewController {
    @IBOutlet weak var progressIndicator: UIProgressView!
    @IBOutlet weak var webView: WKWebView!
    
    weak var delegate: ChartViewControllerDelegate?
    
    override func loadView() {
        super.loadView()
    
        self.webView.configuration.userContentController.add(LeakAvoider(delegate: self), name: "nativeCallbackHandler")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("ChartViewController")
        // Do any additional setup after loading the view.
        self.setupWebView()
        self.urlSetup()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        self.presentUnderConstructionNib()
    }
    
    func setupWebView() {
        self.webView.navigationDelegate = self
        self.webView.uiDelegate = self
        self.webView.configuration.preferences.javaScriptEnabled = true
        self.webView.isOpaque = false
        self.webView.backgroundColor = UIColor.clear
        self.progressIndicator.progress = 0
    }

    func urlSetup() {
        let headerString = "<head><meta name='viewport' content='width=device-width, initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0, user-scalable=no'></head>"
        
        let htmlString = """
            <!-- TradingView Widget BEGIN -->
            <div class="tradingview-widget-container">
                  <div id="tradingview_3682d"></div>
                  <div class="tradingview-widget-copyright"><a href="https://www.tradingview.com/symbols/NASDAQ-AAPL/" rel="noopener" target="_blank"><span class="blue-text">AAPL Chart</span></a> by TradingView</div>
                  <script type="text/javascript" src="https://s3.tradingview.com/tv.js"></script>
                  <script type="text/javascript">
                  new TradingView.widget(
                  {
                  "width": 980,
                  "height": 610,
                  "symbol": "NASDAQ:AAPL",
                  "interval": "D",
                  "timezone": "Etc/UTC",
                  "theme": "light",
                  "style": "1",
                  "locale": "en",
                  "toolbar_bg": "#f1f3f6",
                  "enable_publishing": false,
                  "hide_side_toolbar": false,
                  "allow_symbol_change": true,
                  "container_id": "tradingview_3682d"
                }
                  );
                  </script>
            </div>
            <!-- TradingView Widget END -->
        """

        self.webView.loadHTMLString(headerString + htmlString, baseURL: nil)
        
//        if !(self.modally ?? false) {
//            self.setupRefreshControl()
//            self.presentGIF()
//        }
//        
//        guard let url =  URL(string: (self.urlString?.contains("webview") ?? false) ? (self.urlString ?? "") : "\(self.urlString ?? "")&webview=true&s=customer_app") else { return }
//        var request = URLRequest(url: url)
//        
//        let authValue: String = "Bearer \(getUserToken())"
//        
//        if self.cameFrom != "zendesk" && self.cameFrom != "Amazonaws"{
//            request.setValue(authValue, forHTTPHeaderField: "Authorization")
//        }
//        
//        request.setValue("customer_app", forHTTPHeaderField: "source")
//        request.setValue("ios", forHTTPHeaderField: "d")
//        request.setValue("true", forHTTPHeaderField: "webview")
//        
//        self.webView.load(request)
//
//        self.observation = self.webView.observe(\.estimatedProgress, options: [.new]) { [weak self] webView, _ in
//            guard let self = self else { return }
//            self.progressIndicator.progress = Float(webView.estimatedProgress)
//        }
    }
    
    private func presentUnderConstructionNib() {
        let nib = UnderConstructionViewController(nibName: "UnderConstructionViewController", bundle: nil)
        nib.modalPresentationStyle = .overCurrentContext
        nib.modalTransitionStyle = .crossDissolve
        nib.delegate = self
        DispatchQueue.main.async { self.present(nib, animated: true, completion: nil) }
    }
}

//MARK:- WKWebview Navigation Delegate
extension ChartViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didStartProvisionalNavigation _: WKNavigation!) {
        
        if self.progressIndicator.isHidden {
            // Make sure our animation is visible.
            self.progressIndicator.isHidden = false
        }

        UIView.animate(withDuration: 0.33, animations: {
            self.progressIndicator.alpha = 1.0
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
        self.progressIndicator.progress = 1
        
        UIView.animate(withDuration: 0.33, animations: {
            self.progressIndicator.alpha = 0.0
        }, completion: { done in
            //if got loading presented, dismiss
            self.progressIndicator.isHidden = done
            if self.webView.scrollView.refreshControl?.isRefreshing ?? false {
                self.webView.scrollView.refreshControl?.endRefreshing()
                self.webView.scrollView.refreshControl?.hideRefreshIndicator()
            }
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

extension ChartViewController: UnderConstructionViewControllerDelegate {
    func doDismiss() {
        self.delegate?.underConstruction()
    }
}
