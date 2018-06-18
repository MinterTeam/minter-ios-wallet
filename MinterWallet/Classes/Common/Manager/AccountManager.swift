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
	
	enum AccountManagerError : Error {
		case privateKeyUnableToEncrypt
		case privateKeyEncryptionFaulted
		case privateKeyCanNotBeSaved
	}
	
	//MARK: - Sources
	
	private let database = RealmDatabaseStorage.shared
	private let secureStorage = SecureStorage()
	
	//MARK: -
	
	private let passwordKey = "AccountPassword"
	
	//TODO: Change to random
	private let iv = "pjSfpWAjdSaYpOBy"
	
	//MARK: -
	
	//Account with seed
	
	func account(mnemonic: String, encryptedBy: Account.EncryptedBy = .me) -> Account? {
		guard let seed = seed(mnemonic: mnemonic) else {
			return nil
		}
		
		return account(seed: seed, encryptedBy: encryptedBy)
	}
	
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
		let hash = password.bytes.sha256()
		let data = Data(bytes: hash)
		secureStorage.set(data, forKey: passwordKey)
	}
	
	func password() -> Data? {
		let val = secureStorage.object(forKey: passwordKey) as? Data
		return val
	}
	
	//Generate Seed from mnemonic
	func seed(mnemonic: String, passphrase: String = "") -> Data? {
		return Data(hex: String.seedString(mnemonic, passphrase: passphrase)!)
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
			
			let aes = try AES(key: password.bytes, blockMode: CBC(iv: self.iv.bytes))
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
	
	func mnemonic(for address: String) -> String? {
		guard let encryptedMnemonic = secureStorage.object(forKey: address) as? Data, let password = self.password() else {
			return nil
		}
		
		return decryptMnemonic(encrypted: encryptedMnemonic, password: password)
	}
	
	func decryptMnemonic(encrypted: Data, password: Data) -> String? {
		
		let key = password
		let aes = try? AES(key: password.bytes, blockMode: CBC(iv: self.iv.bytes))
		
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
			return Account(encryptedBy: Account.EncryptedBy(rawValue: dbModel.encryptedBy) ?? .me, address: dbModel.address, isMain: dbModel.isMain)
		}
		
		return res
	}
	
	func loadRemoteAccounts(completion: (([String]) -> ())?) {
		
		guard let accessToken = Session.shared.accessToken else {
			return
		}

		let addressManager = AddressManager.manager(accessToken: accessToken)

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
			dbModel.address = account.address.stripMinterHexPrefix()
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
