// Copyright © 2020 Stormbird PTE. LTD.

import Foundation
import APIKit
import JSONRPCKit
import PromiseKit

class GetNextNonce {
    private let rpcURL: URL
    private let wallet: TBakeWallet.Address

    init(server: RPCServer, wallet: TBakeWallet.Address) {
        self.rpcURL = server.rpcURL
        self.wallet = wallet
    }

    init(rpcURL: URL, wallet: TBakeWallet.Address) {
        self.rpcURL = rpcURL
        self.wallet = wallet
    }

    func promise() -> Promise<Int> {
        let request = EtherServiceRequest(rpcURL: rpcURL, batch: BatchFactory().create(GetTransactionCountRequest(address: wallet, state: "pending")))
        return Session.send(request)
    }
}
