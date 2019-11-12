//
//  Account.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 03/05/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import Foundation

public struct Account {

	public enum EncryptedBy: String {
		case me = "me"
		case bipWallet = "bipWallet"
	}

	// MARK: -

	public var encryptedBy: EncryptedBy
	public var address: String
	public var isMain: Bool
	public var lastBalance: [String: Double] = [:]

	// MARK: -

	public init(encryptedBy: EncryptedBy, address: String, isMain: Bool = false) {
		self.encryptedBy = encryptedBy
		self.address = address
		self.isMain = isMain
	}

	// MARK: -

	public mutating func merge(with account: Account) {
		self.encryptedBy = account.encryptedBy
		self.address = account.address
		self.isMain = account.isMain
	}
}
