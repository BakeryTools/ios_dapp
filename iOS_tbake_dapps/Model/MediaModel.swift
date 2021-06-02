//
//  MediaModel.swift
//  iOS_tbake_dapps
//
//  Created by Danial on 23/05/2021.
//

import UIKit

struct Media {
    let key: String
    let filename: String
    let data: Data
    let mimeType: String
    
    init?(withImage image: UIImage, forKey key: String, filename: String) {
        self.key = key
        self.mimeType = "image/jpeg"
        self.filename = filename
        
        guard let data = image.jpegData(compressionQuality: 1) else { return nil }
        self.data = data
    }
    
}
