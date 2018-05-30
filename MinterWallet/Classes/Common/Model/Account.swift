//
//  Account.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 03/05/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import Foundation


struct Account {
	
	enum EncryptedBy : String {
		case me = "me"
		case bipWallet = "bipWallet"
	}
	
	//MARK: -
	
	var encryptedBy: EncryptedBy
	
	var address: String
	
	var isMain: Bool
	
	var lastBalance: [String : Double] = [:]
	
	//MARK: -
	
	init(encryptedBy: EncryptedBy, address: String, isMain: Bool = false) {
		self.encryptedBy = encryptedBy
		self.address = address
		self.isMain = isMain
	}
	
	//MARK: -

	mutating func merge(with account: Account) {
		self.encryptedBy = account.encryptedBy
		self.address = account.address
		self.isMain = account.isMain
	}

}
