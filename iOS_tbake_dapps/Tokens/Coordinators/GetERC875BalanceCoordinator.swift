// Copyright © 2018 Stormbird PTE. LTD.

import Foundation
import Result

class GetERC875BalanceCoordinator {
    private let server: RPCServer

    init(forServer server: RPCServer) {
        self.server = server
    }

    func getERC875TokenBalance(
        for address: AlphaWallet.Address,
        contract: AlphaWallet.Address,
        completion: @escaping (Result<[String], AnyError>) -> Void
    ) {
        let function = GetERC875Balance()
        callSmartContract(withServer: server, contract: contract, functionName: function.name, abiString: function.abi, parameters: [address.eip55String] as [AnyObject], timeout: TokensDataStore.fetchContractDataTimeout).done { balanceResult in
            let balances = self.adapt(balanceResult["0"])
            completion(.success(balances))
        }.catch {
            completion(.failure(AnyError($0)))
        }
    }

    private func adapt(_ values: Any?) -> [String] {
        guard let array = values as? [Data] else { return [] }
        return array.map { each in
            let value = each.toHexString()
            return "0x\(value)"
        }
    }
}
