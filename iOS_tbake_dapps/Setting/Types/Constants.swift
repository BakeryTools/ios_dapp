// Copyright SIX DAY LLC. All rights reserved.

import Foundation
import BigInt
import web3swift

public struct Constants {
    public static let keychainKeyPrefix = "tbakewallet"
    public static let xdaiDropPrefix = Data(
        [0x58, 0x44, 0x41, 0x49, 0x44, 0x52, 0x4F, 0x50]
    ).hex()

    public static let mainnetMagicLinkHost = ""
    public static let legacyMagicLinkHost = ""
    public static let classicMagicLinkHost = ""
    public static let callistoMagicLinkHost = ""
    public static let kovanMagicLinkHost = ""
    public static let ropstenMagicLinkHost = ""
    public static let rinkebyMagicLinkHost = ""
    public static let poaMagicLinkHost = ""
    public static let sokolMagicLinkHost = ""
    public static let xDaiMagicLinkHost = ""
    public static let goerliMagicLinkHost = ""
    public static let artisSigma1MagicLinkHost = ""
    public static let artisTau1MagicLinkHost = ""
    public static let binanceMagicLinkHost = ""
    public static let binanceTestMagicLinkHost = ""
    public static let hecoMagicLinkHost = ""
    public static let hecoTestMagicLinkHost = ""
    public static let customMagicLinkHost = ""
    public static let fantomMagicLinkHost = ""
    public static let fantomTestMagicLinkHost = ""
    public static let avalancheMagicLinkHost = ""
    public static let avalancheTestMagicLinkHost = ""
    public static let maticMagicLinkHost = ""
    public static let mumbaiTestMagicLinkHost = ""
    public static let optimisticMagicLinkHost = ""
    public static let optimisticTestMagicLinkHost = ""

    public enum Currency {
        static let usd = "USD"
    }
    
    // Magic link networks
    public static let legacyMagicLinkPrefix = ""

    // fee master
    public static let paymentServer = ""
    public static let paymentServerSpawnable = ""
    public static let paymentServerSupportsContractEndPoint = ""
    public static let paymentServerClaimedToken = ""
    public static let currencyDropServer = ""

    // social
    public static let website = "https://bakerytools.io"
    public static let twitterUsername = "bakerytools"

    // support
    public static let dappsBrowserURL = "http://tbake.app"

    //Ethereum null variables
    public static let nullTokenId = "0x0000000000000000000000000000000000000000000000000000000000000000"
    public static let nullTokenIdBigUInt = BigUInt(0)
    public static let burnAddressString = "0x000000000000000000000000000000000000dEaD"
    static let nullAddress = TBakeWallet.Address(uncheckedAgainstNullAddress: "0x0000000000000000000000000000000000000000")!
    static let nativeCryptoAddressInDatabase = nullAddress

    
    //TBAKE token
    static let tbakeToken = TBakeWallet.Address(string: "0x26d6e280f9687c463420908740ae59f712419147")!

    //OpenSea links for erc721 assets
    public static let openseaAPI = "https://api.opensea.io/"
    public static let openseaRinkebyAPI = "https://rinkeby-api.opensea.io/"
    public static let openseaAPIKEY = "11ba1b4f0c4246aeb07b1f8e5a20525f" // X-API-KEY
    //Using "kat" instead of "cryptokitties" to avoid being mistakenly detected by app review as supporting CryptoKitties
    public static let katContractAddress = "0x06012c8cf97bead5deae237070f9587f8e7a266d"

    //xDai dapps
    static let xDaiBridge = URL(string: "https://bridge.xdaichain.com/")!
    private static let rampApiKey = "j5wr7oqktym7z69yyf84bb8a6cqb7qfu5ynmeyvn"
    static let buyXDaiWitRampUrl = "https://buy.ramp.network/?hostApiKey=\(rampApiKey)&hostLogoUrl=https%3A%2F%2Falphawallet.com%2Fwp-content%2Fthemes%2Falphawallet%2Fimg%2Falphawallet-logo.svg&hostAppName=AlphaWallet&swapAsset=xDai"

    static func buyWitRampUrl(asset: String) -> String {
        "https://buy.ramp.network/?hostApiKey=\(rampApiKey)&hostLogoUrl=https%3A%2F%2Falphawallet.com%2Fwp-content%2Fthemes%2Falphawallet%2Fimg%2Falphawallet-logo.svg&hostAppName=AlphaWallet&swapAsset=\(asset)"
    }

    //ENS
    static let ENSRegistrarAddress = TBakeWallet.Address(string: "0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e")!
    static let ENSRegistrarRopsten = ENSRegistrarAddress
    static let ENSRegistrarRinkeby = ENSRegistrarAddress
    static let ENSRegistrarGoerli = ENSRegistrarAddress

    static let gasNowEndpointBaseUrl = "https://www.gasnow.org"
    static let highStandardGasThresholdGwei = BigInt(55)

    //UEFA 721 balances function hash
    static let balances165Hash721Ticket = "0xc84aae17"
    
    //Misc
    public static let etherReceivedNotificationIdentifier = "etherReceivedNotificationIdentifier"
    static let legacy875Addresses = [TBakeWallet.Address(string: "0x830e1650a87a754e37ca7ed76b700395a7c61614")!,
                                            TBakeWallet.Address(string: "0xa66a3f08068174e8f005112a8b2c7a507a822335")!]
    static let legacy721Addresses = [
        TBakeWallet.Address(string: "0x06012c8cf97bead5deae237070f9587f8e7a266d")!,
        TBakeWallet.Address(string: "0xabc7e6c01237e8eef355bba2bf925a730b714d5f")!,
        TBakeWallet.Address(string: "0x71c118b00759b0851785642541ceb0f4ceea0bd5")!,
        TBakeWallet.Address(string: "0x7fdcd2a1e52f10c28cb7732f46393e297ecadda1")!
    ]
    
    static let ensContractOnMainnet = TBakeWallet.Address.ethereumAddress(eip55String: "0x57f1887a8BF19b14fC0dF6Fd9B2acc9Af147eA85")

    static let defaultEnabledServers: [RPCServer] = [.binance_smart_chain] //tukar server tauu. //Danial
    static let defaultEnabledTestnetServers: [RPCServer] = [.ropsten]

    static let tokenScriptUrlSchemeForResources = "tokenscript-resource:///"

    //validator API
    static let tokenScriptValidatorAPI = "https://tbake.app/api/v1/verifyXMLDSig"

    static let launchShortcutKey = "tbakewallet.qrScanner"

    //CurrencyFormatter
    static let formatterFractionDigits = 2

    //EtherNumberFormatter
    static let etherFormatterFractionDigits = 4
}

public struct UnitConfiguration {
    public static let gasPriceUnit: EthereumUnit = .gwei
    public static let gasFeeUnit: EthereumUnit = .ether
    public static let finneyUnit: EthereumUnit = .finney
}
