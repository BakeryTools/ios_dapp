// Copyright SIX DAY LLC. All rights reserved.

import Foundation
import BigInt

struct UnconfirmedTransaction {
    let transactionType: TransactionType
    let value: BigInt
    let recipient: TBakeWallet.Address?
    let contract: TBakeWallet.Address?
    let data: Data?
    let gasLimit: BigInt?
    let tokenId: BigUInt?
    let gasPrice: BigInt?
    let nonce: BigInt?
    // these are not the v, r, s value of a signed transaction
    // but are the v, r, s value of a signed ERC875 order
    // TODO: encapsulate it in the data field
    //TODO who uses this?
    let v: UInt8?
    let r: String?
    let s: String?
    let expiry: BigUInt?
    let indices: [UInt16]?

    init(
        transactionType: TransactionType,
        value: BigInt,
        recipient: TBakeWallet.Address?,
        contract: TBakeWallet.Address?,
        data: Data?,
        tokenId: BigUInt? = nil,
        indices: [UInt16]? = nil,
        gasLimit: BigInt? = nil,
        gasPrice: BigInt? = nil,
        nonce: BigInt? = nil
    ) {
        self.transactionType = transactionType
        self.value = value
        self.recipient = recipient
        self.contract = contract
        self.data = data
        self.tokenId = tokenId
        self.indices = indices
        self.gasLimit = gasLimit
        self.gasPrice = gasPrice
        self.nonce = nonce
        self.v = nil
        self.r = nil
        self.s = nil
        self.expiry = nil
    }
}
