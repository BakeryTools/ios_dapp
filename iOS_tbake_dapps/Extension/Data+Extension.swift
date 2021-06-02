//
//  Data+Extension.swift
//  iOS_tbake_dapps
//
//  Created by Danial on 23/05/2021.
//

import Foundation

extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
