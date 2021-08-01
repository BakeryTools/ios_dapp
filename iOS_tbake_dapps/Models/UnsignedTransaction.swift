// Copyright SIX DAY LLC. All rights reserved.

import Foundation
import BigInt

public struct UnsignedTransaction {
    let value: BigInt
    let account: TBakeWallet.Address
    let to: TBakeWallet.Address?
    let nonce: Int
    let data: Data
    let gasPrice: BigInt
    let gasLimit: BigInt
    let server: RPCServer
    let transactionType: TransactionType
}
