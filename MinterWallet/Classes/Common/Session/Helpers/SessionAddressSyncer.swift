//
//  SessionAddressSyncer.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 14/06/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import Foundation
import RxSwift
import MinterCore
import MinterMy



class SessionAddressSyncer {
	
	var isSyncing = Variable(false)
	
	//MARK: -
	
//	private var addressManager = AddressManager.default
	private let database = RealmDatabaseStorage.shared
	private let accountManager = AccountManager()
	
	
	
	func startSync() {
		
		if isSyncing.value {
			return
		}
		isSyncing.value = true
		let local = loadLocal()
		
		guard let password = accountManager.password() else {
			assert(true)
			self.isSyncing.value = false
			return
		}
		
		loadRemoteAccounts { (addresses) in
			
			let addressesToAdd = addresses.filter({ (address) -> Bool in
				return (local?.filter({ (account) -> Bool in
					return account.address == address.address && address.id != nil
				}).count ?? 0) == 0
			})
			
			addressesToAdd.forEach({ (address) in
				if let encr = address.encrypted {
					
					if let mnemonic = self.accountManager.decryptMnemonic(encrypted: Data(hex: encr), password: password) {
						try? self.accountManager.save(mnemonic: mnemonic, password: password)

						if let account = self.accountManager.account(id: address.id!, mnemonic: mnemonic, encryptedBy: .bipWallet) {
							self.accountManager.saveLocalAccount(account: account)
						}
					}
				}
			})
			
			self.isSyncing.value = false
		}
		
	}
	
	//TODO: Substitute with AccountManager one
	private func loadLocal() -> [Account]? {
		
		let accounts = database.objects(class: AccountDataBaseModel.self, query: nil) as? [AccountDataBaseModel]
		
		let res = accounts?.map { (dbModel) -> Account in
			return Account(id: dbModel.id, encryptedBy: Account.EncryptedBy(rawValue: dbModel.encryptedBy) ?? .me, address: dbModel.address, isMain: dbModel.isMain)
		}
		
		return res
	}
	
	private func loadAppSettings() {
		
	}
	
	
	private var addressManager: MyAddressManager?
	
	private func loadRemoteAccounts(completion: (([Address]) -> ())?) {
		
		guard let client = APIClient.withAuthentication() else {
			completion?([])
			return
		}

		addressManager = MyAddressManager(httpClient: client)
		addressManager?.addresses { (addresses, error) in
			
			var adrs = [Address]()
			
			defer {
				completion?(adrs)
			}
			
			guard nil == error else {
				return
			}
			
			adrs = addresses ?? []
			
		}
	}
	
	func loadMnemonic(address: String) {
		
	}
	
	
}

