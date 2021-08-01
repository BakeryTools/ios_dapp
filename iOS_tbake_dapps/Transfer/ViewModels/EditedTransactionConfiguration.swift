// Copyright © 2020 Stormbird PTE. LTD.

import Foundation
import BigInt

struct EditedTransactionConfiguration {
    private let formatter = EtherNumberFormatter.full

    var gasPrice: BigInt {
        return formatter.number(from: String(gasPriceRawValue), units: UnitConfiguration.gasPriceUnit) ?? BigInt()
    }

    var gasLimit: BigInt {
        BigInt(String(gasLimitRawValue), radix: 10) ?? BigInt()
    }

    var data: Data {
        if dataRawValue.isEmpty {
            return .init()
        } else {
            return .init(hex: dataRawValue.drop0x)
        }
    }

    var gasPriceRawValue: Int
    var gasLimitRawValue: Int
    var dataRawValue: String
    var nonceRawValue: Int?

    var overridenMaxGasPrice: Int?
    var overridenMaxGasLimit: Int?

    let defaultMinGasLimit = Int(GasLimitConfiguration.minGasLimit)
    let defaultMinGasPrice = Int(GasPriceConfiguration.minPrice / BigInt(UnitConfiguration.gasPriceUnit.rawValue))

    private let defaultMaxGasLimit: Int = Int(GasLimitConfiguration.maxGasLimit)
    private let defaultMaxGasPrice: Int = Int(GasPriceConfiguration.maxPrice / BigInt(UnitConfiguration.gasPriceUnit.rawValue))

    var maxGasPrice: Int {
        if let overridenValue = overridenMaxGasPrice {
            return overridenValue
        } else {
            return defaultMaxGasPrice
        }
    }

    var maxGasLimit: Int {
        if let overridenValue = overridenMaxGasLimit {
            return overridenValue
        } else {
            return defaultMaxGasLimit
        }
    }

    mutating func updateMaxGasLimitIfNeeded(_ value: Int) {
        if value > defaultMaxGasLimit {
            overridenMaxGasLimit = value
        } else if value < defaultMinGasLimit {
            overridenMaxGasLimit = nil
        }
    }

    mutating func updateMaxGasPriceIfNeeded(_ value: Int) {
        if value > defaultMaxGasPrice {
            overridenMaxGasPrice = value
        } else if value < defaultMaxGasPrice {
            overridenMaxGasPrice = nil
        }
    }

    init(configuration: TransactionConfiguration) {
        gasLimitRawValue = Int(configuration.gasLimit.description) ?? 21000
        gasPriceRawValue = Int(configuration.gasPrice / BigInt(UnitConfiguration.gasPriceUnit.rawValue))
        nonceRawValue = Int(configuration.nonce.flatMap { String($0) } ?? "")
        dataRawValue = configuration.data.hexEncoded.add0x

        updateMaxGasLimitIfNeeded(gasLimitRawValue)
        updateMaxGasPriceIfNeeded(gasPriceRawValue)
    }

    var configuration: TransactionConfiguration {
        return .init(gasPrice: gasPrice, gasLimit: gasLimit, data: data, nonce: nonceRawValue)
    }

    var isGasPriceValid: Bool {
        return gasPrice >= 0
    }

    var isGasLimitValid: Bool {
        return gasLimit <= ConfigureTransaction.gasLimitMax && gasLimit >= 0
    }

    var totalFee: BigInt {
        return gasPrice * gasLimit
    }

    var isTotalFeeValid: Bool {
        return totalFee <= ConfigureTransaction.gasFeeMax && totalFee >= 0
    }

    var isNonceValid: Bool {
        guard let nonce = nonceRawValue else { return true }
        return nonce >= 0
    }
}