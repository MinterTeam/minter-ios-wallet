//
//  BaseCellItem.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 04/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import Foundation

class BaseCellItem {

	let reuseIdentifier: String
	
	let identifier: String

	init(reuseIdentifier: String, identifier: String) {
		self.reuseIdentifier = reuseIdentifier
		self.identifier = identifier
	}

}
