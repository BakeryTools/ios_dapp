//
//  TBakeWalletAddressExtension.swift
//  iOS_tbake_dapps
//
//  Created by Danial on 01/08/2021.
//

import Foundation
import TrustKeystore
import web3swift

extension TBakeWallet.Address {
    //TODO multiple versions of init() that accept address types from other libraries goes here. Anymore?
    init(address: EthereumAddress) {
        self = .ethereumAddress(eip55String: address.address)
    }

    init(address: Address) {
        self = .ethereumAddress(eip55String: address.eip55String)
    }

    func sameContract(as contract: EthereumAddress) -> Bool {
        return eip55String == contract.address
    }
}

extension EthereumAddress {
    init(address: TBakeWallet.Address) {
        //EthereumAddress(Data) is much faster than EthereumAddress(String). This is significant because we can make a few hundred calls
//        let data = Data.fromHex(address.eip55String)!
//        self.init(data)!

        //During testing we found that EthereumAddress(address.eip55String) is faster then self.init(data)!
        //approx time is 0.000980973243713379 while with using self.init(data)! is 2.8967857360839844e-05 seconds.

        self.init(address.eip55String)!
    }
}

extension TrustKeystore.Address {
    init(address: TBakeWallet.Address) {
        self.init(uncheckedAgainstNullAddress: address.eip55String)!
    }
}

