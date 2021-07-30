// Copyright © 2018 Stormbird PTE. LTD.

import Foundation

protocol AssetDefinitionBackingStore {
    var delegate: AssetDefinitionBackingStoreDelegate? { get set }
    var badTokenScriptFileNames: [TokenScriptFileIndices.FileName] { get }
    var conflictingTokenScriptFileNames: (official: [TokenScriptFileIndices.FileName], overrides: [TokenScriptFileIndices.FileName], all: [TokenScriptFileIndices.FileName]) { get }
    var contractsWithTokenScriptFileFromOfficialRepo: [TBakeWallet.Address] { get }

    subscript(contract: TBakeWallet.Address) -> String? { get set }
    func lastModifiedDateOfCachedAssetDefinitionFile(forContract contract: TBakeWallet.Address) -> Date?
    func forEachContractWithXML(_ body: (TBakeWallet.Address) -> Void)
    func isOfficial(contract: TBakeWallet.Address) -> Bool
    func isCanonicalized(contract: TBakeWallet.Address) -> Bool
    func hasConflictingFile(forContract contract: TBakeWallet.Address) -> Bool
    func hasOutdatedTokenScript(forContract contract: TBakeWallet.Address) -> Bool
    func getCacheTokenScriptSignatureVerificationType(forXmlString xmlString: String) -> TokenScriptSignatureVerificationType?
    func writeCacheTokenScriptSignatureVerificationType(_ verificationType: TokenScriptSignatureVerificationType, forContract contract: TBakeWallet.Address, forXmlString xmlString: String)
    func deleteFileDownloadedFromOfficialRepoFor(contract: TBakeWallet.Address)
}

protocol AssetDefinitionBackingStoreDelegate: AnyObject {
    func invalidateAssetDefinition(forContract contract: TBakeWallet.Address)
    func badTokenScriptFilesChanged(in: AssetDefinitionBackingStore)
}
