// Copyright SIX DAY LLC. All rights reserved.

import Foundation

struct ERC20Contract: Decodable {
    let address: String
    let name: String
    let totalSupply: String
    let decimals: Int
    let symbol: String

    //TODO forced unwrap is not good
    var contractAddress: TBakeWallet.Address! {
        return TBakeWallet.Address(uncheckedAgainstNullAddress: address)!
    }
}

struct LocalizedOperation: Decodable {
    let from: String
    let to: String
    let type: OperationType
    let value: String
    let contract: ERC20Contract

    enum CodingKeys: String, CodingKey {
        case from
        case to
        case type
        case value
        //case tokenID
        case contract
    }

    var fromAddress: TBakeWallet.Address? {
        return TBakeWallet.Address(uncheckedAgainstNullAddress: from)
    }

    var toAddress: TBakeWallet.Address? {
        return TBakeWallet.Address(uncheckedAgainstNullAddress: to)
    }
}
