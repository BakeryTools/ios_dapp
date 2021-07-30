// Copyright © 2018 Stormbird PTE. LTD.

import Alamofire

protocol AssetDefinitionStoreDelegate: AnyObject {
    func listOfBadTokenScriptFilesChanged(in: AssetDefinitionStore )
}

/// Manage access to and cache asset definition XML files
class AssetDefinitionStore {
    enum Result {
        case cached
        case updated
        case unmodified
        case error
    }

    //TODO ugly hack. Check where it's read to know why it's needed
    static var instance: AssetDefinitionStore!

    private var httpHeaders: HTTPHeaders = {
        guard let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String else { return [:] }
        return [
            "Accept": "application/tokenscript+xml; charset=UTF-8",
            "X-Client-Name": TokenScript.repoClientName,
            "X-Client-Version": appVersion,
            "X-Platform-Name": TokenScript.repoPlatformName,
            "X-Platform-Version": UIDevice.current.systemVersion
        ]
    }()
    private var lastModifiedDateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "E, dd MMM yyyy HH:mm:ss z"
        df.timeZone = TimeZone(secondsFromGMT: 0)
        return df
    }()
    private var lastContractInPasteboard: String?
    private var tokenScriptBodyChangedSubscribers: [(TBakeWallet.Address) -> Void] = []
    private var tokenScriptSignatureChangedSubscribers: [(TBakeWallet.Address) -> Void] = []
    private var backingStore: AssetDefinitionBackingStore

    lazy var assetAttributesCache: AssetAttributesCache = AssetAttributesCache(assetDefinitionStore: self)
    weak var delegate: AssetDefinitionStoreDelegate?
    var listOfBadTokenScriptFiles: [TokenScriptFileIndices.FileName] {
        return backingStore.badTokenScriptFileNames
    }
    var conflictingTokenScriptFileNames: (official: [TokenScriptFileIndices.FileName], overrides: [TokenScriptFileIndices.FileName], all: [TokenScriptFileIndices.FileName]) {
        return backingStore.conflictingTokenScriptFileNames
    }

    var contractsWithTokenScriptFileFromOfficialRepo: [TBakeWallet.Address] {
        return backingStore.contractsWithTokenScriptFileFromOfficialRepo
    }

    //TODO move
    static var standardTokenScriptStyles: String {
        return """
               <style type="text/css">
               @font-face {
               font-family: 'SourceSansPro';
               src: url('\(Constants.tokenScriptUrlSchemeForResources)SourceSansPro-Light.otf') format('opentype');
               font-weight: lighter;
               }
               @font-face {
               font-family: 'SourceSansPro';
               src: url('\(Constants.tokenScriptUrlSchemeForResources)SourceSansPro-Regular.otf') format('opentype');
               font-weight: normal;
               }
               @font-face {
               font-family: 'SourceSansPro';
               src: url('\(Constants.tokenScriptUrlSchemeForResources)SourceSansPro-Semibold.otf') format('opentype');
               font-weight: bolder;
               }
               @font-face {
               font-family: 'SourceSansPro';
               src: url('\(Constants.tokenScriptUrlSchemeForResources)SourceSansPro-Bold.otf') format('opentype');
               font-weight: bold;
               }
               .token-card {
               padding: 0pt;
               margin: 0pt;
               }
               </style>
               """
    }

    init(backingStore: AssetDefinitionBackingStore = AssetDefinitionDiskBackingStoreWithOverrides()) {
        self.backingStore = backingStore
        self.backingStore.delegate = self
        AssetDefinitionStore.instance = self
    }

    func hasConflict(forContract contract: TBakeWallet.Address) -> Bool {
        return backingStore.hasConflictingFile(forContract: contract)
    }

    func hasOutdatedTokenScript(forContract contract: TBakeWallet.Address) -> Bool {
        return backingStore.hasOutdatedTokenScript(forContract: contract)
    }

    //Calling this in >= iOS 14 will trigger a scary "TBakeWallet pasted from <app>" message
    func enableFetchXMLForContractInPasteboard() {
        NotificationCenter.default.addObserver(self, selector: #selector(fetchXMLForContractInPasteboard), name: UIApplication.didBecomeActiveNotification, object: nil)
    }

    func fetchXMLs(forContracts contracts: [TBakeWallet.Address]) {
        for each in contracts {
            fetchXML(forContract: each)
        }
    }

    subscript(contract: TBakeWallet.Address) -> String? {
        get {
            backingStore[contract]
        }
        set(value) {
            backingStore[contract] = value
        }
    }

    private func cacheXml(_ xml: String, forContract contract: TBakeWallet.Address) {
        backingStore[contract] = xml
    }

    func isOfficial(contract: TBakeWallet.Address) -> Bool {
        return backingStore.isOfficial(contract: contract)
    }

    func isCanonicalized(contract: TBakeWallet.Address) -> Bool {
        return backingStore.isCanonicalized(contract: contract)
    }

    func subscribeToBodyChanges(_ subscribe: @escaping (_ contract: TBakeWallet.Address) -> Void) {
        tokenScriptBodyChangedSubscribers.append(subscribe)
    }

    func subscribeToSignatureChanges(_ subscribe: @escaping (_ contract: TBakeWallet.Address) -> Void) {
        tokenScriptSignatureChangedSubscribers.append(subscribe)
    }

    /// useCacheAndFetch: when true, the completionHandler will be called immediately and a second time if an updated XML is fetched. When false, the completionHandler will only be called up fetching an updated XML
    ///
    /// IMPLEMENTATION NOTE: Current implementation will fetch the same XML multiple times if this function is called again before the previous attempt has completed. A check (which requires tracking completion handlers) hasn't been implemented because this doesn't usually happen in practice
    func fetchXML(forContract contract: TBakeWallet.Address, useCacheAndFetch: Bool = false, completionHandler: ((Result) -> Void)? = nil) {
        if useCacheAndFetch && self[contract] != nil {
            completionHandler?(.cached)
        }
        guard let url = urlToFetch(contract: contract) else { return }
        Alamofire.request(
                url,
                method: .get,
                headers: httpHeadersWithLastModifiedTimestamp(forContract: contract)
        ).response { [weak self] response in
            guard let strongSelf = self else { return }
            if response.response?.statusCode == 304 {
                completionHandler?(.unmodified)
            } else if response.response?.statusCode == 406 {
                completionHandler?(.error)
            } else if response.response?.statusCode == 404 {
                completionHandler?(.error)
            } else if response.response?.statusCode == 200 {
                if let xml = response.data.flatMap({ String(data: $0, encoding: .utf8) }).nilIfEmpty {
                    //Note that Alamofire converts the 304 to a 200 if caching is enabled (which it is, by default). So we'll never get a 304 here. Checking against Charles proxy will show that a 304 is indeed returned by the server with an empty body. So we compare the contents instead. https://github.com/Alamofire/Alamofire/issues/615
                    if xml == strongSelf[contract] {
                        completionHandler?(.unmodified)
                    } else if strongSelf.isTruncatedXML(xml: xml) {
                        strongSelf.fetchXML(forContract: contract, useCacheAndFetch: false) { result in
                            completionHandler?(result)
                        }
                    } else {
                        strongSelf.cacheXml(xml, forContract: contract)
                        XMLHandler.invalidate(forContract: contract)
                        completionHandler?(.updated)
                        strongSelf.triggerBodyChangedSubscribers(forContract: contract)
                        strongSelf.triggerSignatureChangedSubscribers(forContract: contract)
                    }
                } else {
                    completionHandler?(.error)
                }
            }
        }
    }

    private func isTruncatedXML(xml: String) -> Bool {
        //Safety check against a truncated file download
        return !xml.trimmed.hasSuffix(">")
    }

    private func triggerBodyChangedSubscribers(forContract contract: TBakeWallet.Address) {
        tokenScriptBodyChangedSubscribers.forEach { $0(contract) }
    }

    private func triggerSignatureChangedSubscribers(forContract contract: TBakeWallet.Address) {
        tokenScriptSignatureChangedSubscribers.forEach { $0(contract) }
    }

    @objc private func fetchXMLForContractInPasteboard() {
        guard let contents = UIPasteboard.general.string?.trimmed else { return }
        guard lastContractInPasteboard != contents else { return }
        guard CryptoAddressValidator.isValidAddress(contents) else { return }
        guard let address = TBakeWallet.Address(string: contents) else { return }
        defer { lastContractInPasteboard = contents }
        fetchXML(forContract: address)
    }

    private func urlToFetch(contract: TBakeWallet.Address) -> URL? {
        let name = contract.eip55String
        return URL(string: TokenScript.repoServer)?.appendingPathComponent(name)
    }

    private func lastModifiedDateOfCachedAssetDefinitionFile(forContract contract: TBakeWallet.Address) -> Date? {
        return backingStore.lastModifiedDateOfCachedAssetDefinitionFile(forContract: contract)
    }

    private func httpHeadersWithLastModifiedTimestamp(forContract contract: TBakeWallet.Address) -> HTTPHeaders {
        var result = httpHeaders
        if let lastModified = lastModifiedDateOfCachedAssetDefinitionFile(forContract: contract) {
            result["IF-Modified-Since"] = string(fromLastModifiedDate: lastModified)
            return result
        } else {
            return result
        }
    }

    func string(fromLastModifiedDate date: Date) -> String {
        return lastModifiedDateFormatter.string(from: date)
    }

    func forEachContractWithXML(_ body: (TBakeWallet.Address) -> Void) {
        backingStore.forEachContractWithXML(body)
    }

    func invalidateSignatureStatus(forContract contract: TBakeWallet.Address) {
        triggerSignatureChangedSubscribers(forContract: contract)
    }

    func getCacheTokenScriptSignatureVerificationType(forXmlString xmlString: String) -> TokenScriptSignatureVerificationType? {
        return backingStore.getCacheTokenScriptSignatureVerificationType(forXmlString: xmlString)
    }

    func writeCacheTokenScriptSignatureVerificationType(_ verificationType: TokenScriptSignatureVerificationType, forContract contract: TBakeWallet.Address, forXmlString xmlString: String) {
        return backingStore.writeCacheTokenScriptSignatureVerificationType(verificationType, forContract: contract, forXmlString: xmlString)
    }

    func contractDeleted(_ contract: TBakeWallet.Address) {
        XMLHandler.invalidate(forContract: contract)
        backingStore.deleteFileDownloadedFromOfficialRepoFor(contract: contract)
    }
}

extension AssetDefinitionStore: AssetDefinitionBackingStoreDelegate {
    func invalidateAssetDefinition(forContract contract: TBakeWallet.Address) {
        XMLHandler.invalidate(forContract: contract)
        triggerBodyChangedSubscribers(forContract: contract)
        triggerSignatureChangedSubscribers(forContract: contract)
        fetchXML(forContract: contract)
    }

    func badTokenScriptFilesChanged(in: AssetDefinitionBackingStore) {
        //Careful to not fire immediately because even though we are on the main thread; while we are modifying the indices, we can't read from it or there'll be a crash
        DispatchQueue.main.async {
            self.delegate?.listOfBadTokenScriptFilesChanged(in: self)
        }
    }
}
