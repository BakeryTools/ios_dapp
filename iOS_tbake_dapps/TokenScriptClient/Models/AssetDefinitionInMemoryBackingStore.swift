// Copyright © 2018 Stormbird PTE. LTD.

import Foundation

class AssetDefinitionInMemoryBackingStore: AssetDefinitionBackingStore {
    private var xmls = [TBakeWallet.Address: String]()

    weak var delegate: AssetDefinitionBackingStoreDelegate?
    var badTokenScriptFileNames: [TokenScriptFileIndices.FileName] {
        return .init()
    }
    var conflictingTokenScriptFileNames: (official: [TokenScriptFileIndices.FileName], overrides: [TokenScriptFileIndices.FileName], all: [TokenScriptFileIndices.FileName]) {
        return (official: [], overrides: [], all: [])
    }

    var contractsWithTokenScriptFileFromOfficialRepo: [TBakeWallet.Address] {
        return .init()
    }

    subscript(contract: TBakeWallet.Address) -> String? {
        get {
            return xmls[contract]
        }
        set(xml) {
            //TODO validate XML signature first
            xmls[contract] = xml
        }
    }

    func lastModifiedDateOfCachedAssetDefinitionFile(forContract contract: TBakeWallet.Address) -> Date? {
        return nil
    }

    func forEachContractWithXML(_ body: (TBakeWallet.Address) -> Void) {
        xmls.forEach { contract, _ in
            body(contract)
        }
    }

    func isOfficial(contract: TBakeWallet.Address) -> Bool {
        return false
    }

    func isCanonicalized(contract: TBakeWallet.Address) -> Bool {
        return true
    }

    func hasConflictingFile(forContract contract: TBakeWallet.Address) -> Bool {
        return false
    }

    func hasOutdatedTokenScript(forContract contract: TBakeWallet.Address) -> Bool {
        return false
    }

    func getCacheTokenScriptSignatureVerificationType(forXmlString xmlString: String) -> TokenScriptSignatureVerificationType? {
        return nil
    }

    func writeCacheTokenScriptSignatureVerificationType(_ verificationType: TokenScriptSignatureVerificationType, forContract contract: TBakeWallet.Address, forXmlString xmlString: String) {
        //do nothing
    }

    func deleteFileDownloadedFromOfficialRepoFor(contract: TBakeWallet.Address) {
        xmls[contract] = nil
    }
}
