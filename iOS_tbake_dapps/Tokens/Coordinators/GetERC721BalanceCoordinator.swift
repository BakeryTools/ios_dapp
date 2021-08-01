import Foundation
import BigInt
import PromiseKit
import Result

class GetERC721BalanceCoordinator: CallbackQueueProvider {
    var queue: DispatchQueue?

    private let server: RPCServer

    init(forServer server: RPCServer, queue: DispatchQueue? = nil) {
        self.server = server
        self.queue = queue
    }

    func getERC721TokenBalance(
            for address: TBakeWallet.Address,
            contract: TBakeWallet.Address,
            completion: @escaping (ResultResult<BigUInt, AnyError>.t) -> Void
    ) {
        let function = GetERC721Balance()
        callSmartContract(withServer: server, contract: contract, functionName: function.name, abiString: function.abi, parameters: [address.eip55String] as [AnyObject], timeout: TokensDataStore.fetchContractDataTimeout).done(on: queue, { balanceResult in
            let balance = self.adapt(balanceResult["0"] as Any)
            completion(.success(balance))
        }).catch(on: queue, { error in
            completion(.failure(AnyError(Web3Error(description: "Error extracting result from \(contract.eip55String).\(function.name)(): \(error)"))))
        })
    }

    private func adapt(_ value: Any) -> BigUInt {
        if let value = value as? BigUInt {
            return value
        } else {
            return BigUInt(0)
        }
    }
}
