// Copyright © 2020 Stormbird PTE. LTD.

import Foundation
import RealmSwift
import PromiseKit

protocol EventsDataStoreProtocol {
    func getLastMatchingEventSortedByBlockNumber(forContract contract: TBakeWallet.Address, tokenContract: TBakeWallet.Address, server: RPCServer, eventName: String) -> Promise<EventInstanceValue?>
    func add(events: [EventInstanceValue], forTokenContract contract: TBakeWallet.Address) -> Promise<Void>
    func deleteEvents(forTokenContract contract: TBakeWallet.Address)
    func getMatchingEvents(forContract contract: TBakeWallet.Address, tokenContract: TBakeWallet.Address, server: RPCServer, eventName: String, filterName: String, filterValue: String) -> [EventInstance]
    func subscribe(_ subscribe: @escaping (_ contract: TBakeWallet.Address) -> Void)
}

//TODO rename to indicate it's for instances, not activity
class EventsDataStore: EventsDataStoreProtocol {
    private let realm: Realm
    private var subscribers: [(TBakeWallet.Address) -> Void] = []

    init(realm: Realm) {
        self.realm = realm
    }

    func subscribe(_ subscribe: @escaping (_ contract: TBakeWallet.Address) -> Void) {
        subscribers.append(subscribe)
    }

    private func triggerSubscribers(forContract contract: TBakeWallet.Address) {
        subscribers.forEach { $0(contract) }
    }

    func getMatchingEvents(forContract contract: TBakeWallet.Address, tokenContract: TBakeWallet.Address, server: RPCServer, eventName: String, filterName: String, filterValue: String) -> [EventInstance] {
        Array(realm.objects(EventInstance.self)
                .filter("contract = '\(contract.eip55String)'")
                .filter("tokenContract = '\(tokenContract.eip55String)'")
                .filter("chainId = \(server.chainID)")
                .filter("eventName = '\(eventName)'")
                //Filter stored as string, so we do a string comparison
                .filter("filter = '\(filterName)=\(filterValue)'"))
    }

    func deleteEvents(forTokenContract contract: TBakeWallet.Address) {
        let events = getEvents(forTokenContract: contract)
        delete(events: events)
    }

    private func getEvents(forTokenContract tokenContract: TBakeWallet.Address) -> Results<EventInstance> {
        realm.objects(EventInstance.self)
                .filter("tokenContract = '\(tokenContract.eip55String)'")
    }

    private func delete<S: Sequence>(events: S) where S.Element: EventInstance {
        try? realm.write {
            realm.delete(events)
        }
    }

    func getLastMatchingEventSortedByBlockNumber(forContract contract: TBakeWallet.Address, tokenContract: TBakeWallet.Address, server: RPCServer, eventName: String) -> Promise<EventInstanceValue?> {
        return Promise { seal in
            let event = Array(realm.threadSafe.objects(EventInstance.self)
                .filter("contract = '\(contract.eip55String)'")
                .filter("tokenContract = '\(tokenContract.eip55String)'")
                .filter("chainId = \(server.chainID)")
                .filter("eventName = '\(eventName)'")
                .sorted(byKeyPath: "blockNumber"))
                .map{ EventInstanceValue(event: $0) }
                .last

            seal.fulfill(event)
        }
    }

    func add(events: [EventInstanceValue], forTokenContract contract: TBakeWallet.Address) -> Promise<Void> {
        if events.isEmpty {
            return .value(())
        }

        return Promise { seal in
            do {
                let realm = self.realm.threadSafe
                try realm.write {
                    let eventsToSave = events.map { EventInstance(event: $0) }
                    realm.add(eventsToSave, update: .all)

                    seal.fulfill(())
                }
            } catch {
                seal.reject(error)
            }
        }
    }
}
