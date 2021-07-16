// Copyright © 2018 Stormbird PTE. LTD.

import Foundation
import RealmSwift

class MigrationInitializer: Initializer {
    let account: Wallet

    lazy var config: Realm.Configuration = RealmConfiguration.configuration(for: account)

    init(account: Wallet) {
        self.account = account
    }

    func perform() {
        config.schemaVersion = 9
        //NOTE: use [weak self] to avoid memory leak
        config.migrationBlock = { [weak self] migration, oldSchemaVersion in
            guard let strongSelf = self else { return }

            if oldSchemaVersion < 2 {
                //Fix bug created during multi-chain implementation. Where TokenObject instances are created from transfer Transaction instances, with the primaryKey as a empty string; so instead of updating an existing TokenObject, a duplicate TokenObject instead was created but with primaryKey empty
                migration.enumerateObjects(ofType: TokenObject.className()) { oldObject, newObject in
                    guard oldObject != nil else { return }
                    guard let newObject = newObject else { return }
                    if let primaryKey = newObject["primaryKey"] as? String, primaryKey.isEmpty {
                        migration.delete(newObject)
                        return
                    }
                }
            }
            if oldSchemaVersion < 3 {
                migration.enumerateObjects(ofType: Transaction.className()) { oldObject, newObject in
                    guard oldObject != nil else { return }
                    guard let newObject = newObject else { return }
                    newObject["isERC20Interaction"] = false
                }
            }
            if oldSchemaVersion < 4 {
                migration.enumerateObjects(ofType: TokenObject.className()) { oldObject, newObject in
                    guard let oldObject = oldObject else { return }
                    guard let newObject = newObject else { return }
                    //Fix bug introduced when OpenSea suddenly includes the DAI stablecoin token in their results with an existing versioned API endpoint, and we wrongly tagged it as ERC721, possibly crashing when we fetch the balance (casting a very large ERC20 balance with 18 decimals to an Int)
                    guard let contract = oldObject["contract"] as? String, contract == "0x89d24A6b4CcB1B6fAA2625fE562bDD9a23260359" else { return }
                    newObject["rawType"] = "ERC20"
                }
            }
            if oldSchemaVersion < 5 {
                migration.enumerateObjects(ofType: TokenObject.className()) { oldObject, newObject in
                    guard let oldObject = oldObject else { return }
                    guard let newObject = newObject else { return }
                    //Fix bug introduced when OpenSea suddenly includes the DAI stablecoin token in their results with an existing versioned API endpoint, and we wrongly tagged it as ERC721 with decimals=0. The earlier migration (version=4) only set the type back to ERC20, but the decimals remained as 0
                    guard let contract = oldObject["contract"] as? String, contract == "0x89d24A6b4CcB1B6fAA2625fE562bDD9a23260359" else { return }
                    newObject["decimals"] = 18
                }
            }
            if oldSchemaVersion < 6 {
                migration.enumerateObjects(ofType: TokenObject.className()) { oldObject, newObject in
                    guard oldObject != nil else { return }
                    guard let newObject = newObject else { return }

                    newObject["shouldDisplay"] = true
                    newObject["sortIndex"] = RealmOptional<Int>(nil)
                }
            }
            if oldSchemaVersion < 7 {
                //Fix bug where we marked all transactions as completed successfully without checking `isError` from Etherscan
                migration.deleteData(forType: Transaction.className())
                for each in RPCServer.allCases {
                    Config.setLastFetchedErc20InteractionBlockNumber(0, server: each, wallet: strongSelf.account.address)
                }
                migration.deleteData(forType: EventActivity.className())
            }
            if oldSchemaVersion < 8 {
                //Clear all transactions data so we can fetch them again and capture `LocalizedOperationObject` children correctly
                migration.deleteData(forType: Transaction.className())
                migration.deleteData(forType: LocalizedOperationObject.className())
                for each in RPCServer.allCases {
                    Config.setLastFetchedErc20InteractionBlockNumber(0, server: each, wallet: strongSelf.account.address)
                }
                migration.deleteData(forType: EventActivity.className())
            }

            if oldSchemaVersion < 9 {
                //no-op
            }
        }
    }
}

extension MigrationInitializer {

    //We use the existence of realm databases as a heuristic to determine if there are wallets (including watched ones)
    static var hasRealmDatabasesForWallet: Bool {
        let documentsDirectory = URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])
        if let contents = (try? FileManager.default.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: nil))?.filter({ $0.lastPathComponent.starts(with: "0") }) {
            return !contents.isEmpty
        } else {
            //No reason why it should come here
            return false
        }
    }

    //NOTE: This function is using to make sure that wallets in user defaults will be removed after restoring backup from iCloud. Realm files don't backup to iCloud but user defaults does backed up.
    static func removeWalletsIfRealmFilesMissed(keystore: Keystore) {
        for wallet in keystore.wallets {
            let migration = MigrationInitializer(account: wallet)

            guard let path = migration.config.fileURL else { continue }

            //NOTE: make sure realm files exists, if not then delete this wallets from user defaults.
            if FileManager.default.fileExists(atPath: path.path) {
                //no op
            } else {
                _ = keystore.delete(wallet: wallet)
            }
        }
    }

    func oneTimeCreationOfOneDatabaseToHoldAllChains(assetDefinitionStore: AssetDefinitionStore) {
        let migration = self

        #if DEBUG
            print(migration.config.fileURL!)
            print(migration.config.fileURL!.deletingLastPathComponent())
        #endif

        let exists: Bool
        if let path = migration.config.fileURL?.path {
            exists = FileManager.default.fileExists(atPath: path)
        } else {
            exists = false
        }
        guard !exists else { return }

        migration.perform()
        let realm = try! Realm(configuration: migration.config)

        do {
            try realm.write {
                for each in RPCServer.allCases {
                    let migration = MigrationInitializerForOneChainPerDatabase(account: account, server: each, assetDefinitionStore: assetDefinitionStore)
                    migration.perform()
                    let oldPerChainDatabase = try! Realm(configuration: migration.config)
                    for each in oldPerChainDatabase.objects(Bookmark.self) {
                        realm.create(Bookmark.self, value: each)
                    }
                    for each in oldPerChainDatabase.objects(DelegateContract.self) {
                        realm.create(DelegateContract.self, value: each)
                    }
                    for each in oldPerChainDatabase.objects(DeletedContract.self) {
                        realm.create(DeletedContract.self, value: each)
                    }
                    for each in oldPerChainDatabase.objects(HiddenContract.self) {
                        realm.create(HiddenContract.self, value: each)
                    }
                    for each in oldPerChainDatabase.objects(History.self) {
                        realm.create(History.self, value: each)
                    }
                    for each in oldPerChainDatabase.objects(TokenObject.self) {
                        realm.create(TokenObject.self, value: each)
                    }
                    for each in oldPerChainDatabase.objects(Transaction.self) {
                        realm.create(Transaction.self, value: each)
                    }
                }
            }
            for each in RPCServer.allCases {
                let migration = MigrationInitializerForOneChainPerDatabase(account: account, server: each, assetDefinitionStore: assetDefinitionStore)
                let realmUrl = migration.config.fileURL!
                let realmUrls = [
                    realmUrl,
                    realmUrl.appendingPathExtension("lock"),
                    realmUrl.appendingPathExtension("note"),
                    realmUrl.appendingPathExtension("management")
                ]
                for each in realmUrls {
                    try? FileManager.default.removeItem(at: each)
                }
            }
        } catch {
            //no-op
        }
    }
}

