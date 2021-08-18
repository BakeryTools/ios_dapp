//
//  WebService.swift
//  recommend-customer-ios
//
//  Created by Danial on 07/04/2020.
//  Copyright © 2020 Danial. All rights reserved.
//

import Kingfisher
import UIKit

enum imageStatus: String {
    case success
    case failure
}

public class WebService {
    //Post Data using Struct
    // MARK: - postData
    /// - parameter url:                Compulsary for api url
    /// - parameter httpBody:           Compulsary to post data to  webservice
    /// - parameter completionHandler:  The completion handler data, just pass return data to viewcontroller
    func postData(_ url: String, httpMethod: String? = "POST", httpBody: Data? = nil, completion: @escaping ((_ data: Data)->())){
        guard let url = URL(string: url) else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = httpMethod
        // Set HTTP Request Header
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("ios", forHTTPHeaderField: "d")
        request.httpBody = httpBody
        
        let config = URLSessionConfiguration.default
        config.waitsForConnectivity = true
        config.timeoutIntervalForResource = 300 //set 5minit
        config.timeoutIntervalForRequest = 300 //set 5minit
        
        URLSession(configuration: config).dataTask(with: request) { (data, response, error) in
            guard let data = data else { return }
            completion(data)
        }.resume()
    }
    
    // MARK: - getData
    /// - parameter url:                Compulsary for api url
    /// - parameter httpBody:           Optional if need pass data to webservice
    /// - parameter completionHandler:  The completion handler data, just pass return data to viewcontroller
    func getData(_ url: String, completion: @escaping ((_ data: Data)->())){
        let encodedUrl = url.replacingOccurrences(of: " ", with: "+")
        guard let url = URL(string: encodedUrl) else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        // Set HTTP Request Header
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("ios", forHTTPHeaderField: "d")
        
        let config = URLSessionConfiguration.default
        config.waitsForConnectivity = true
        config.timeoutIntervalForResource = 300
        config.timeoutIntervalForRequest = 300
        
        URLSession(configuration: config).dataTask(with: request) { (data, response, error) in
            guard let data = data else { return }
            completion(data)
        }.resume()
    }
}
