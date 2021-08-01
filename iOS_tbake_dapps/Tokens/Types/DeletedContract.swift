// Copyright © 2018 Stormbird PTE. LTD.

import Foundation
import RealmSwift

class DeletedContract: Object {
    @objc dynamic var primaryKey: String = ""
    @objc dynamic var chainId: Int = 0
    @objc dynamic var contract: String = ""

    convenience init(contractAddress: TBakeWallet.Address, server: RPCServer) {
        self.init()
        self.contract = contractAddress.eip55String
        self.chainId = server.chainID
        self.primaryKey = "\(self.contract)-\(server.chainID)"
    }

    override static func primaryKey() -> String? {
        return "primaryKey"
    }

    var contractAddress: TBakeWallet.Address {
        return TBakeWallet.Address(uncheckedAgainstNullAddress: contract)!
    }
}
