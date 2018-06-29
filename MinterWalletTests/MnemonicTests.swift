//
//  MnemonicTests.swift
//  MinterWalletTests
//
//  Created by Alexey Sidorov on 18/06/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import XCTest
import CryptoSwift
import MinterCore
@testable import MinterWallet


class MnemonicTests: XCTestCase {
	
	let accountManager = AccountManager()
    
	override func setUp() {
		super.setUp()
	}
	
	override func tearDown() {

		super.tearDown()
	}
	
	func testEnc() {
		let mnemonic = "globe arrange forget twice potato nurse ice dwarf arctic piano scorpion tube"
		let rawPassword = "123456".bytes.sha256()
		let encryptedMnemonic = "e28513acd2336aa048b68cf382a45ec0bc7bed1e7d35f2b7bf0b6c1406e6f3c57fc91c08ba972f7ed82050e54867e1624b2e2f145aa8d0a40d51ad4eb258faa7e2a9ccaed555d15d7830df188897c054"
		
		let res = try! accountManager.encryptedMnemonic(mnemonic: mnemonic, password: Data(bytes: rawPassword))
		
		
		XCTAssert(res?.toHexString() == encryptedMnemonic)
		
	}
	
	func testDecrypt() {
		let encryptedMnemonic = "e28513acd2336aa048b68cf382a45ec0bc7bed1e7d35f2b7bf0b6c1406e6f3c57fc91c08ba972f7ed82050e54867e1624b2e2f145aa8d0a40d51ad4eb258faa7e2a9ccaed555d15d7830df188897c054"
		let mnemonic = "globe arrange forget twice potato nurse ice dwarf arctic piano scorpion tube"
		let rawPassword = "123456".bytes.sha256()
		
		let res = try! accountManager.decryptMnemonic(encrypted: Data(hex: encryptedMnemonic), password: Data(bytes: rawPassword))
		
		XCTAssert(res == mnemonic)
		
	}
	
	func testDecryptedAddress() {
		let encryptedMnemonic = "518984845bf2cb4ca6e3e0cf830cab1feaa41b08f475dd97243ab299e612e668bac1e6b5bd98a6fedecb711c1c346e0e0ac58be1463d2cc6e7b06fb1413c14b857e979a9ff235a07ab011fa8183b319e"
//		let mnemonic = "solve print three view soft oblige awake typical kite solution online shallow"
		let rawPassword = "123456".bytes.sha256()
		
		let mnemonic = try! accountManager.decryptMnemonic(encrypted: Data(hex: encryptedMnemonic), password: Data(bytes: rawPassword))
		
		let address = accountManager.address(from: mnemonic!)
		
		XCTAssert("Mx" + address! == "Mx228e5a68b847d169da439ec15f727f08233a7ca6")
		
	}
	
	func testEncrypt() {
		let mnemonic = "globe arrange forget twice potato nurse ice dwarf arctic piano scorpion tube"
		let rawPassword = "123456"
		var IV = Data(bytes: "Minter seed".bytes)
		IV.append(Data(repeating: UInt8(0), count: 16 - IV.count))
		
		let encryptedMnemonic = "e28513acd2336aa048b68cf382a45ec0bc7bed1e7d35f2b7bf0b6c1406e6f3c57fc91c08ba972f7ed82050e54867e1624b2e2f145aa8d0a40d51ad4eb258faa7e2a9ccaed555d15d7830df188897c054"
		
		let aes = try! AES(key: rawPassword.bytes.sha256(), blockMode: CBC(iv: IV.bytes))
		
		let ciphertext = try! aes.encrypt(Array(mnemonic.utf8))
		
		XCTAssert(Data(bytes: ciphertext).toHexString() == encryptedMnemonic)
	}
	

	//
	
	func testPasswordHash() {
		let originalPassword = "123456"
		let passwordHash = "49dc52e6bf2abe5ef6e2bb5b0f1ee2d765b922ae6cc8b95d39dc06c21c848f8c"
		
		XCTAssert(originalPassword.sha256().sha256() == passwordHash)
	}
	
	func testAccountPassword() {
		let originalPassword = "123456"
		let passwordHash = "49dc52e6bf2abe5ef6e2bb5b0f1ee2d765b922ae6cc8b95d39dc06c21c848f8c"
		
		XCTAssert(accountManager.accountPassword(originalPassword) == passwordHash)
	}
	
	
	
}
