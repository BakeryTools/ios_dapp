//
//  ABI.swift
//  AlphaWallet
//
//  Created by Vladyslav Shepitko on 11.05.2021.
//

import UIKit

extension TBakeWallet {
    enum Ethereum {
        enum ABI {}
    }
}
extension TBakeWallet.Ethereum.ABI {
    static let ERC20: Data = {
        let url = Bundle.main.url(forResource: "ERC20", withExtension: "json")!
        return try! Data(contentsOf: url)
    }() 
}

