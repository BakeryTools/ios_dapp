//
//  WebService.swift
//  iOS_tbake_dapps
//
//  Created by Danial on 23/05/2021.
//  Copyright © 2021 Danial. All rights reserved.
//

import Kingfisher
import UIKit

typealias Parameters = [String: String]

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
        let authValue: String = "Bearer \(getUserToken())"
        request.httpMethod = httpMethod
        // Set HTTP Request Header
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(authValue, forHTTPHeaderField: "Authorization")
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
        let authValue: String = "Bearer \(getUserToken())"
        request.httpMethod = "GET"
        // Set HTTP Request Header
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(authValue, forHTTPHeaderField: "Authorization")
        
        let config = URLSessionConfiguration.default
        config.waitsForConnectivity = true
        config.timeoutIntervalForResource = 300
        config.timeoutIntervalForRequest = 300
        
        URLSession(configuration: config).dataTask(with: request) { (data, response, error) in
            guard let data = data else { return }
            completion(data)
        }.resume()
    }
    
    func postFormData(_ mediaImage: [Media]? = nil, urlWs: String, parameters: Parameters, completion: @escaping ((_ data: Data?,_ error: Error?)->())){
           
        guard let url = URL(string: urlWs) else { return }
        var request = URLRequest(url: url)
        let authValue: String = "Bearer \(getUserToken())"
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(authValue, forHTTPHeaderField: "Authorization")
        
        let boundary = generateBoundary()
        
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        let dataBody = createDataBody(withParameters: parameters, media: mediaImage, boundary: boundary)
        request.httpBody = dataBody
        
        let config = URLSessionConfiguration.default
        config.waitsForConnectivity = true
        config.timeoutIntervalForResource = 300
        config.timeoutIntervalForRequest = 300
        
        URLSession(configuration: config).dataTask(with: request) { (data, response, error) in
            completion(data, error)
            
        }.resume()
    }
       
    func generateBoundary() -> String {
        return "Recommend-\(NSUUID().uuidString)"
    }
       
    func createDataBody(withParameters params: Parameters?, media: [Media]?, boundary: String) -> Data {
        
        let lineBreak = "\r\n"
        var body = Data()
        
        if let parameters = params {
            for (key, value) in parameters {
                body.append("--\(boundary + lineBreak)")
                body.append("Content-Disposition: form-data; name=\"user[\(key)]\"\(lineBreak + lineBreak)")
                body.append("\(value + lineBreak)")
            }
        }
        
        if let media = media {
            for photo in media {
                body.append("--\(boundary + lineBreak)")
                body.append("Content-Disposition: form-data; name=\"user[\(photo.key)]\"; filename=\"\(photo.filename)\"\(lineBreak)")
                body.append("Content-Type: \(photo.mimeType + lineBreak + lineBreak)")
                body.append(photo.data)
                body.append(lineBreak)
            }
        }
        
        body.append("--\(boundary)--\(lineBreak)")
        
        return body
    }
    
    // MARK: - loadImageData
      /// - parameter parentImgView:      Optional to put UIView to loading shimmering
      /// - parameter imageView:          Compulsory to put imageView to assign new image
      /// - parameter imageURL:           Passed image url (string or url) only to load image, check with status to show image **(not necessary to convert to URL)
      /// - parameter defaultImage:       Default image as placeholder image if imageURL is nil
      /// - parameter completionHandler:  The completion handler image, just pass image to UIImage.image
    static func loadImageData(_ parentImgView: UIView? = nil,
                              imageView: UIImageView,
                              imageURL: String,
                              defaultImage: UIImage,
                              completionHandler: @escaping (_ status: imageStatus)->Void) {
          
        // show activity indicator
        let activityIndicator = UIActivityIndicatorView(style: .medium)
        imageView.addSubview(activityIndicator)
        activityIndicator.center = imageView.center
        activityIndicator.color = UIColor.hexStringToUIColor(hex: "#2294CA", 1.0)
        activityIndicator.startAnimating()
        
        // convert http url to https
        var comps = URLComponents(string: imageURL)
        comps?.scheme = "https"
        let httpsImageURL = comps?.string ?? ""
        let url = URL(string: httpsImageURL)
        
        // retrieve from request url
        imageView.kf.setImage(with: url, completionHandler:  { _ in
            ImageCache.default.retrieveImageInDiskCache(forKey: url?.cacheKey ?? "", options: [.waitForCache]) { result in
                switch result {
                case .success(let image):
                    
                    DispatchQueue.main.async {
                        activityIndicator.stopAnimating()
                        activityIndicator.removeFromSuperview()
                        imageView.image = (image != nil) ? image : defaultImage
                        completionHandler((image != nil) ? imageStatus.success : imageStatus.failure)
                    }
                case .failure:
                    DispatchQueue.main.async {
                        activityIndicator.stopAnimating()
                        activityIndicator.removeFromSuperview()
                        imageView.image = defaultImage
                        completionHandler(imageStatus.failure)
                    }
                }
            }
        }) // end kingfisher
    }
}
