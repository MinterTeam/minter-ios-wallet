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
import MinterMy


class AccountManager {
	
	init(secureStorage: Storage = SecureStorage()) {
		self.secureStorage = secureStorage
	}
	
	enum AccountManagerError : Error {
		case privateKeyUnableToEncrypt
		case privateKeyEncryptionFaulted
		case privateKeyCanNotBeSaved
	}
	
	//MARK: - Sources
	
	private let database = RealmDatabaseStorage.shared
	private let secureStorage: Storage
	
	
	//MARK: -
	
	//TODO: rename
	private let passwordKey = "AccountPassword"
	
	private let iv = Data(bytes: "Minter seed".bytes).setLengthRight(16)
	
	//MARK: -
	
	//Account with seed
	
	func accountPassword(_ password: String) -> String {
		return password.sha256().sha256()
	}
	
	func account(id: Int, mnemonic: String, encryptedBy: Account.EncryptedBy = .me) -> Account? {
		guard let seed = seed(mnemonic: mnemonic) else {
			return nil
		}
		
		return account(id: id, seed: seed, encryptedBy: encryptedBy)
	}
	
	func account(id: Int, seed: Data, encryptedBy: Account.EncryptedBy = .me) -> Account? {
		let newPk = self.privateKey(from: seed)
		
		guard
			let publicKey = RawTransactionSigner.publicKey(privateKey: newPk.raw, compressed: false)?.dropFirst(),
			let address = RawTransactionSigner.address(publicKey: publicKey) else {
				return nil
		}
		
		var acc = Account(id: id, encryptedBy: .me, address: address)
		acc.encryptedBy = encryptedBy
		return acc
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
	//TODO: rename to encryption key
	func save(password: String) {
		let hash = password.bytes.sha256()
		let data = Data(bytes: hash)
//		DispatchQueue.main.async {
			self.secureStorage.set(data, forKey: self.passwordKey)
//		}
	}
	
	//TODO: rename to encryption key
	func password() -> Data? {
		let val = secureStorage.object(forKey: passwordKey) as? Data
		return val
	}
	
	func save(encryptionKey: Data) {
		DispatchQueue.main.async {
			self.secureStorage.set(encryptionKey, forKey: self.passwordKey)
		}
	}
	
	func deleteEncryptionKey() {
		DispatchQueue.main.async {
			self.secureStorage.removeObject(forKey: self.passwordKey)
		}
	}
	
	//Generate Seed from mnemonic
	func seed(mnemonic: String, passphrase: String = "") -> Data? {
		
		if let seed = RawTransactionSigner.seed(from: mnemonic) {
			return Data(hex: seed)
		}
		return nil
	}
	
	//Save PK to SecureStorage
	
	func save(mnemonic: String, password: Data) throws {
		
		guard let key = self.address(from: mnemonic) else {
			return
		}
		
		guard let data = try? encryptedMnemonic(mnemonic: mnemonic, password: password) else {
			
			throw AccountManagerError.privateKeyCanNotBeSaved
		}
		
		secureStorage.set(data!, forKey: key)
	}

	func encryptedMnemonic(mnemonic: String, password: Data) throws -> Data? {
		do {
			
			let aes = try AES(key: password.bytes, blockMode: CBC(iv: self.iv!.bytes))
			let ciphertext = try aes.encrypt(Array(mnemonic.utf8))
			
			guard ciphertext.count > 0 else {
				//throw error
				assert(true)
				throw AccountManagerError.privateKeyEncryptionFaulted
			}
			return Data(bytes: ciphertext)
		}
		catch {
			throw AccountManagerError.privateKeyUnableToEncrypt
		}
		return nil
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
	
	//MARK: -
	
	func privateKey(for address: String) -> PrivateKey? {
		guard let mnemonic = self.mnemonic(for: address), let seed = self.seed(mnemonic: mnemonic) else {
			return nil
		}
		
		return self.privateKey(from: seed)
	}
	
	func mnemonic(for address: String) -> String? {
		guard let encryptedMnemonic = secureStorage.object(forKey: address) as? Data, let password = self.password() else {
			return nil
		}
		
		return decryptMnemonic(encrypted: encryptedMnemonic, password: password)
	}
	
	func encryptedMnemonic(for address: String) -> Data? {
		return secureStorage.object(forKey: address) as? Data
	}
	
	func decryptMnemonic(encrypted: Data, password: Data) -> String? {
		
		let key = password
		let aes = try? AES(key: password.bytes, blockMode: CBC(iv: self.iv!.bytes))
		
		guard let decrypted = try? aes?.decrypt(encrypted.bytes) else {
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
			return Account(id: dbModel.id, encryptedBy: Account.EncryptedBy(rawValue: dbModel.encryptedBy) ?? .me, address: dbModel.address, isMain: dbModel.isMain)
		}
		
		return res
	}
	
	func loadRemoteAccounts(completion: (([String]) -> ())?) {
		
		guard let accessToken = Session.shared.accessToken.value else {
			return
		}

		let addressManager = MyAddressManager.manager(accessToken: accessToken)

		addressManager.addresses { (addresses, error) in

			var addresses = [String]()

			defer {
				completion?(addresses)
			}

			guard nil == error else {
				return
			}
		}
	}
	
	//MARK: -

	func saveLocalAccount(account: Account) {
		
		guard let res = database.objects(class: AccountDataBaseModel.self, query: "address == \"\(account.address)\"")?.first as? AccountDataBaseModel else {
			let dbModel = AccountDataBaseModel()
			dbModel.id = account.id
			dbModel.address = account.address.stripMinterHexPrefix().lowercased()
			dbModel.encryptedBy = account.encryptedBy.rawValue
			dbModel.isMain = account.isMain
			
			database.add(object: dbModel)
			
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
