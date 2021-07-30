// Copyright © 2020 Stormbird PTE. LTD.

import Foundation
import BigInt
import TrustKeystore
import web3swift

struct DecodedFunctionCall {
    enum FunctionType {
//NOTE: Not sure if we need these functions
//        case erc20TotalSupply
//        case erc20BalanceOf(address: TBakeWallet.Address)
//        case erc20Allowance(address: TBakeWallet.Address, address: TBakeWallet.Address)
//        case erc20TransferFrom(address: TBakeWallet.Address, address: TBakeWallet.Address, value: BigUInt)
        case erc20Transfer(recipient: TBakeWallet.Address, value: BigUInt)
        case erc20Approve(spender: TBakeWallet.Address, value: BigUInt)
        case nativeCryptoTransfer(value: BigUInt)
        case others
    }

    static let erc20Transfer = (name: "transfer", interfaceHash: "a9059cbb", byteCount: 68)
    static let erc20Approve = (name: "approve", interfaceHash: "095ea7b3", byteCount: 68)

    let name: String
    let arguments: [(type: ABIType, value: AnyObject)]
    let type: FunctionType

    init?(data: Data) {
        guard let decoded = DecodedFunctionCall.decode(data: data, abi: TBakeWallet.Ethereum.ABI.ERC20) else { return nil }
        self = decoded
    }

    init(name: String, arguments: [(type: ABIType, value: AnyObject)], type: FunctionType) {
        self.name = name
        self.arguments = arguments
        self.type = type
    }

    static func nativeCryptoTransfer(value: BigUInt) -> DecodedFunctionCall {
        .init(name: "Transfer", arguments: .init(), type: .nativeCryptoTransfer(value: value))
    }

    init(name: String, arguments: [(type: ABIType, value: AnyObject)]) {
        self.name = name
        self.arguments = arguments
        self.type = DecodedFunctionCall.FunctionType(name: name, arguments: arguments)
    }
}
