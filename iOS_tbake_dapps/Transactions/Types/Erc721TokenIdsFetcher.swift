// Copyright © 2021 Stormbird PTE. LTD.

import Foundation
import PromiseKit

protocol Erc721TokenIdsFetcher: class {
    func tokenIdsForErc721Token(contract: AlphaWallet.Address, inAccount account: AlphaWallet.Address) -> Promise<[String]>
}