//
//  AccountManager.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 03/05/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import Foundation
import CryptoSwift
import MinterCore


class AccountManager {
	
	//MARK: - Sources
	
	private let database = RealmDatabaseStorage.shared
	
	//MARK: -
	
	//TODO: Change to random password
	private let iv = "pjSfpWAjdSaYpOBy"
	
	//MARK: -
	
	//Account with seed
	func account(seed: Data, encryptedBy: Account.EncryptedBy = .me) -> Account? {
		let pk = PrivateKey(seed: seed)
		
		let newPk = pk.derive(at: 44, hardened: true).derive(at: 60, hardened: true).derive(at: 0, hardened: true).derive(at: 0).derive(at: 0)
		
		guard
			let publicKey = RawTransactionSigner.publicKey(privateKey: newPk.raw, compressed: false)?.dropFirst(),
			let address = RawTransactionSigner.address(publicKey: publicKey) else {
				return nil
		}
		
		return Account(encryptedBy: .me, address: address)
	}
	
	//Generate Seed from mnemonic
	func seed(mnemonic: String, passphrase: String = "mnemonic") -> Data? {
		return Data(hex: String.seedString(mnemonic, passphrase: passphrase)!)
	}
	
	//Save PK to SecureStorage
	func save(seed: String, password: String) {
//		let key = seed.sha256()
//		do {
//			let aes = try AES(key: password, iv: iv) // aes128
//			let ciphertext = try aes.encrypt(Array(seed.utf8))
//		} catch {
//
//		}
	}
	
	//MARK: -
	
	func setMain(isMain: Bool, account: inout Account) {
		account.isMain = isMain
		
		if account.encryptedBy == .me {
			saveLocalAccount(account: account)
		}
	}
	
	
	//MARK: -
	
	func loadLocalAccounts() -> [Account]? {
		
		let accounts = database.objects(class: AccountDataBaseModel.self, query: nil) as? [AccountDataBaseModel]
		
		let res = accounts?.map { (dbModel) -> Account in
			return Account(encryptedBy: Account.EncryptedBy(rawValue: dbModel.encryptedBy) ?? .me, address: dbModel.address, isMain: dbModel.isMain)
		}
		
		return res
	}
	
	func loadRemoteAccounts() -> [Account]? {
		return []
	}
	
	//MARK: -

	func saveLocalAccount(account: Account) {
		
		guard let res = database.objects(class: AccountDataBaseModel.self, query: "address == \"\(account.address)\"")?.first as? AccountDataBaseModel else {
			return
		}
		
		let addressesToUnset = database.objects(class: AccountDataBaseModel.self) as? [AccountDataBaseModel]

		database.update {
			addressesToUnset?.forEach({ (addr) in
				addr.isMain = false
			})
			res.substitute(with: account)
		}
	}
	
}
