//
//  URLViewModel.swift
//  iOS_tbake_dapps
//
//  Created by Danial on 16/07/2021.
//

import UIKit

protocol URLViewModel {
    var urlText: String? { get }
    var title: String { get }
    var imageURL: URL? { get }
    var placeholderImage: UIImage? { get }
}

extension URLViewModel {
    var placeholderImage: UIImage? {
        return R.image.launch_icon()
    }
}
