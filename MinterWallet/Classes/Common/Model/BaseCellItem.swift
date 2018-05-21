//
//  BaseCellItem.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 04/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import Foundation
import RxDataSources



class BaseCellItem : IdentifiableType, Equatable {

	let reuseIdentifier: String
	
	let identifier: String

	init(reuseIdentifier: String, identifier: String) {
		self.reuseIdentifier = reuseIdentifier
		self.identifier = identifier
	}
	
	//MARK: - IdentifiableType
	
	typealias Identity = String
	
	var identity : Identity {
		return identifier
	}
	
	//MARK: - Equatable
	
	static func == (lhs: BaseCellItem, rhs: BaseCellItem) -> Bool {
		return lhs.identifier == rhs.identifier
	}

}
