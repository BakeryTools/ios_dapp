// Copyright © 2020 Stormbird PTE. LTD.

import Foundation
import PromiseKit

class GasNowGasPriceEstimator {
    func fetch() -> Promise<GasNowPriceEstimates> {
        let alphaWalletProvider = TBakeWalletProviderFactory.makeProvider()
        return alphaWalletProvider.request(.gasPriceEstimate).map { response -> GasNowPriceEstimates in
            try response.map(GasNowPriceEstimates.self)
        }
    }
}
