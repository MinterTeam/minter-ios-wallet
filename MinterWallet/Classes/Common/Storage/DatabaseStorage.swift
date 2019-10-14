//
//  DatabaseStorage.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 14/05/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import Foundation
import RealmSwift

protocol DatabaseStorageModel: class {}

protocol DatabaseStorage {
	func add(object: DatabaseStorageModel)
	func objects(class cls: DatabaseStorageModel.Type, query: String?) -> [DatabaseStorageModel]?
}

class RealmDatabaseStorage: DatabaseStorage {

	private init() {}

	static let shared = RealmDatabaseStorage()

	// MARK: -

	private let realm = try! Realm()// swiftlint:disable:this force_try

	// MARK: -

	func add(object: DatabaseStorageModel) {
		guard let obj = object as? Object else {
			assert(true, "Should be an instance of Object")
			return
		}

		try! realm.write {// swiftlint:disable:this force_try
			realm.add(obj)
		}
	}

	// MARK: -

	func objects(class cls: DatabaseStorageModel.Type, query: String? = nil) -> [DatabaseStorageModel]? {
		guard let clss = cls as? Object.Type else {
			return nil
		}

		var results = realm.objects(clss)
		if nil != query {
			results = results.filter(query!)
		}
		return Array(results) as? [DatabaseStorageModel]
	}

	// MARK: -

	func update(updates: (() -> ())) {
		try! realm.write {// swiftlint:disable:this force_try
			updates()
		}
	}

	// MARK: -

	func removeAll() {
		try! realm.write {// swiftlint:disable:this force_try
			realm.deleteAll()
		}
	}
}
