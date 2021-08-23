//
//  UIViewController+Extension.swift
//  sejasa-customer-ios
//
//  Created by Danial on 08/04/2021.
//  Copyright © 2021 Danial. All rights reserved.
//

import Foundation
import WebKit

extension UIViewController {    
    func setupRefreshControl(_ webView: WKWebView) {
        webView.scrollView.refreshControl = UIRefreshControl()
        webView.scrollView.refreshControl?.backgroundColor = UIColor.clear
        webView.scrollView.refreshControl?.tintColor = UIColor.clear
        webView.scrollView.refreshControl?.addRefreshView()
    }
}
