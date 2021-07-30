// Copyright SIX DAY LLC. All rights reserved.

import Foundation

struct TokenUpdate {
    let address: TBakeWallet.Address
    let server: RPCServer
    let name: String
    let symbol: String
    let decimals: Int
    let tokenType: TokenType
    var primaryKey: String {
         return TokenObject.generatePrimaryKey(fromContract: address, server: server)
    }
}
