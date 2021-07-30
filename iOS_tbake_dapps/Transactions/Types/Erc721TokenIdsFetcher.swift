// Copyright © 2021 Stormbird PTE. LTD.

import Foundation
import PromiseKit

protocol Erc721TokenIdsFetcher: AnyObject {
    func tokenIdsForErc721Token(contract: TBakeWallet.Address, inAccount account: TBakeWallet.Address) -> Promise<[String]>
}
