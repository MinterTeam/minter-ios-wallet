//
//  AdvancedModeBaseViewModel.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 30/05/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import Foundation
import MinterCore
import MinterMy

class AccountantBaseViewModel: BaseViewModel {

	let accountManager = AccountManager()
	private let databaseStorage = RealmDatabaseStorage.shared

	func saveAccount(id: Int, mnemonic: String, isLocal: Bool = true) -> Account? {

		guard
			let seed = accountManager.seed(mnemonic: mnemonic, passphrase: ""),
			let account = accountManager.account(id: id,
																					 seed: seed,
																					 encryptedBy: isLocal ? .me : .bipWallet) else {
				return nil
		}

		var password = accountManager.password()

		if nil == password {
			accountManager.save(password: accountManager.generateRandomPassword(length: 32))
			password = accountManager.password()
		}

		guard nil != password else {
			assert(true)
			return nil
		}

		//save mnemonic
		do {
			try accountManager.save(mnemonic: mnemonic, password: password!)
		} catch {
			return nil
		}

		let accounts = databaseStorage.objects(class: AccountDataBaseModel.self) as? [AccountDataBaseModel]
		let hasObjects = !(accounts?.count == 0)

		//No repeated accounts allowed
		guard (accounts ?? []).filter({ (acc) -> Bool in
			return acc.address == account.address
		}).count == 0 else {
			return nil
		}

		let dbModel = AccountDataBaseModel()
		dbModel.address = account.address
		dbModel.encryptedBy = account.encryptedBy.rawValue
		dbModel.isMain = !hasObjects
		databaseStorage.add(object: dbModel)

		SessionHelper.reloadAccounts()

		return account
	}

}
