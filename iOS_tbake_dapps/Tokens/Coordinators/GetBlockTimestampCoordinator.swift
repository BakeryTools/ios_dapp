import Foundation
import BigInt
import PromiseKit
import web3swift

class GetBlockTimestampCoordinator {
    //TODO persist?
    private static var blockTimestampCache = ThreadSafeDictionary<RPCServer, [BigUInt: Promise<Date>]>()

    func getBlockTimestamp(_ blockNumber: BigUInt, onServer server: RPCServer) -> Promise<Date> {
        var cacheForServer = Self.blockTimestampCache[server] ?? .init()
        if let datePromise = cacheForServer[blockNumber] {
            return datePromise
        }

        guard let web3 = try? getCachedWeb3(forServer: server, timeout: 6) else {
            return Promise(error: Web3Error(description: "Error creating web3 for: \(server.rpcURL) + \(server.web3Network)"))
        }

        let promise: Promise<Date> = Promise { seal in
            firstly {
                web3swift.web3.Eth(provider: web3.provider, web3: web3).getBlockByNumberPromise(blockNumber)
            }.map {
                $0.timestamp
            }.done {
                seal.fulfill($0)
            }.catch {
                seal.reject($0)
            }
        }

        cacheForServer[blockNumber] = promise
        Self.blockTimestampCache[server] = cacheForServer
        return promise
    }
}

