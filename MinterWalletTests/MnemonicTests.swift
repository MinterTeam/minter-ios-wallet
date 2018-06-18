//
//  MnemonicTests.swift
//  MinterWalletTests
//
//  Created by Alexey Sidorov on 18/06/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import XCTest
import CryptoSwift
@testable import MinterWallet


class MnemonicTests: XCTestCase {
	
	let accountManager = AccountManager()
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
	
	func testEnc() {
		let mnemonic = "globe arrange forget twice potato nurse ice dwarf arctic piano scorpion tube"
		let rawPassword = "123456".bytes.sha256()
		let encryptedMnemonic = "82678708bf256c89978a1705a3302c6258e2ae9bf9a0daad6982f2c02a6efb49f98ff01321c0252c389c9c2f56ea977653d8867ac42862c0e97524256dee50788224867e65079d4fc2b3a35fe8b425fa"
		
		let res = try! accountManager.encryptedMnemonic(mnemonic: mnemonic, password: Data(bytes: rawPassword))
		
		
		XCTAssert(res?.toHexString() == encryptedMnemonic)
		
	}
	
	func testDecrypt() {
		let encryptedMnemonic = "82678708bf256c89978a1705a3302c6258e2ae9bf9a0daad6982f2c02a6efb49f98ff01321c0252c389c9c2f56ea977653d8867ac42862c0e97524256dee50788224867e65079d4fc2b3a35fe8b425fa"
		let mnemonic = "globe arrange forget twice potato nurse ice dwarf arctic piano scorpion tube"
		let rawPassword = "123456".bytes.sha256()
		
		let res = try! accountManager.decryptMnemonic(encrypted: Data(hex: encryptedMnemonic), password: Data(bytes: rawPassword))
		
		XCTAssert(res == mnemonic)
		
	}
    
    func testEncrypt() {
			let mnemonic = "globe arrange forget twice potato nurse ice dwarf arctic piano scorpion tube"
			let rawPassword = "123456"
			let IV = "pjSfpWAjdSaYpOBy"
			let encryptedMnemonic = "fd5ade23281968499a2b5a7e53eaa2295a195a1794abe985c66edc0744fcf945118238c1a2a598f7940aa186b2f9f9bf2515bc49bd41c1fe29b27a2f8da96e40254306c4f4d605352b567f074ec6deb3"
			
			let aes = try! AES(key: rawPassword.bytes.sha256(), blockMode: CBC(iv: IV.bytes))
			
			let ciphertext = try! aes.encrypt(Array(mnemonic.utf8))
			
			XCTAssert(Data(bytes: ciphertext).toHexString() == encryptedMnemonic)
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
