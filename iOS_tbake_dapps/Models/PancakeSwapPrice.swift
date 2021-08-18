//
//  PancakeSwapPrice.swift
//  iOS_tbake_dapps
//
//  Created by Danial on 18/08/2021.
//

import Foundation


struct PancakeSwapPrice: Codable {
    var updated_at: Int?
    var data: TokenDetails?
}

struct TokenDetails: Codable {
    var name: String?
    var symbol: String?
    var price: String?
    var price_BNB: String?
}
