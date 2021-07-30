
import Foundation
import BigInt
import Result
import web3swift

class GetERC20BalanceCoordinator: CallbackQueueProvider {
    private let server: RPCServer
    internal let queue: DispatchQueue?

    init(forServer server: RPCServer, queue: DispatchQueue? = nil) {
        self.server = server
        self.queue = queue
    }

    func getBalance(
            for address: TBakeWallet.Address,
            contract: TBakeWallet.Address,
            completion: @escaping (ResultResult<BigInt, AnyError>.t) -> Void
    ) {
        let functionName = "balanceOf"
        callSmartContract(withServer: server, contract: contract, functionName: functionName, abiString: web3swift.Web3.Utils.erc20ABI, parameters: [address.eip55String] as [AnyObject], timeout: TokensDataStore.fetchContractDataTimeout).done(on: queue, { balanceResult in
            if let balanceWithUnknownType = balanceResult["0"] {
                let string = String(describing: balanceWithUnknownType)
                if let balance = BigInt(string) {
                    completion(.success(balance))
                } else {
                    completion(.failure(AnyError(Web3Error(description: "Error extracting result from \(contract.eip55String).\(functionName)()"))))
                }
            } else {
                completion(.failure(AnyError(Web3Error(description: "Error extracting result from \(contract.eip55String).\(functionName)()"))))
            }
        }).catch(on: queue, {
            completion(.failure(AnyError($0)))
        })
    }
}
