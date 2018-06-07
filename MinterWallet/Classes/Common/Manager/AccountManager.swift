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
	private let secureStorage = SecureStorage()
	
	//MARK: -
	
	private let passwordKey = "AccountPassword"
	
	//TODO: Change to random
	private let iv = "pjSfpWAjdSaYpOBy"
	
	//MARK: -
	
	//Account with seed
	func account(seed: Data, encryptedBy: Account.EncryptedBy = .me) -> Account? {
		let newPk = self.privateKey(from: seed)
		
		guard
			let publicKey = RawTransactionSigner.publicKey(privateKey: newPk.raw, compressed: false)?.dropFirst(),
			let address = RawTransactionSigner.address(publicKey: publicKey) else {
				return nil
		}
		
		return Account(encryptedBy: .me, address: address)
	}
	
	func privateKey(from seed: Data) -> PrivateKey {
		let pk = PrivateKey(seed: seed)
		let newPk = pk.derive(at: 44, hardened: true).derive(at: 60, hardened: true).derive(at: 0, hardened: true).derive(at: 0).derive(at: 0)
		return newPk
	}
	
	//
	func generateRandomPassword(length: Int) -> String {
		return String.random(length: length)
	}
	
	//save hash of password
	func save(password: String) {
		let hash = password.sha256() as NSString
		secureStorage.set(hash, forKey: passwordKey)
	}
	
	func password() -> String? {
		let val = secureStorage.object(forKey: passwordKey) as? NSString
		return val as String?
	}
	
	//Generate Seed from mnemonic
	func seed(mnemonic: String, passphrase: String = "") -> Data? {
		return Data(hex: String.seedString(mnemonic, passphrase: passphrase)!)
	}
	
	//Save PK to SecureStorage
	func save(mnemonic: String, password: String) {
		
		guard let key = self.address(from: mnemonic) else {
			return
		}
		
		do {
			let aes = try AES(key: String(password.prefix(32)), iv: iv) // aes128
			let ciphertext = try aes.encrypt(Array(mnemonic.utf8))
			
			guard ciphertext.count > 0 else {
				//throw error
				assert(true)
				return
			}
			
			let data = Data(bytes: ciphertext)
			secureStorage.set(data, forKey: key)
			
		} catch {
			//error
			assert(true)
		}
	}
	
	func address(from mnemonic: String) -> String? {
		
		guard let seed = self.seed(mnemonic: mnemonic) else {
			return nil
		}
		
		let pk = PrivateKey(seed: seed)
		
		let newPk = pk.derive(at: 44, hardened: true).derive(at: 60, hardened: true).derive(at: 0, hardened: true).derive(at: 0).derive(at: 0)
		
		guard
			let publicKey = RawTransactionSigner.publicKey(privateKey: newPk.raw, compressed: false)?.dropFirst(),
			let address = RawTransactionSigner.address(publicKey: publicKey) else {
				return nil
		}
		
		return address
	}
	
	func mnemonic(for address: String) -> String? {
		guard let encriptedMnemonic = secureStorage.object(forKey: address) as? Data else {
			return nil
		}
		guard let password = self.password() else {
			return nil
		}
		
		let key = String(password.prefix(32))
		let aes = try? AES(key: key, iv: iv) // aes128
		
		guard let decrypted = try? aes?.decrypt(encriptedMnemonic.bytes) else {
			return nil
		}
		
		let mnemonic = Data(bytes: decrypted!)
		
		return String(data: mnemonic, encoding: .utf8)
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
