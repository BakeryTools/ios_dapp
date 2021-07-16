//
// Created by James Sangalli on 14/7/18.
// Copyright © 2018 Stormbird PTE. LTD.
//

import Foundation
import BigInt
import PromiseKit
import Result

class GetERC721BalanceCoordinator {
    private let server: RPCServer

    init(forServer server: RPCServer) {
        self.server = server
    }

    func getERC721TokenBalance(
            for address: AlphaWallet.Address,
            contract: AlphaWallet.Address,
            completion: @escaping (ResultResult<BigUInt, AnyError>.t) -> Void
    ) {
        let function = GetERC721Balance()
        callSmartContract(withServer: server, contract: contract, functionName: function.name, abiString: function.abi, parameters: [address.eip55String] as [AnyObject], timeout: TokensDataStore.fetchContractDataTimeout).done { balanceResult in
            let balance = self.adapt(balanceResult["0"] as Any)
            completion(.success(balance))
        }.catch { error in
            completion(.failure(AnyError(Web3Error(description: "Error extracting result from \(contract.eip55String).\(function.name)(): \(error)"))))
        }
    }

    private func adapt(_ value: Any) -> BigUInt {
        if let value = value as? BigUInt {
            return value
        } else {
            return BigUInt(0)
        }
    }
}