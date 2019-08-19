//
//  BaseCellItem.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 04/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import Foundation
import RxDataSources

public class BaseCellItem: IdentifiableType, Equatable {

	let reuseIdentifier: String

	let identifier: String

	init(reuseIdentifier: String, identifier: String) {
		self.reuseIdentifier = reuseIdentifier
		self.identifier = identifier
	}

	// MARK: - IdentifiableType

	public typealias Identity = String

	public var identity : Identity {
		return identifier
	}

	// MARK: - Equatable

	public static func == (lhs: BaseCellItem, rhs: BaseCellItem) -> Bool {
		return lhs.identifier == rhs.identifier
	}

}

class TransactionCellItem: BaseCellItem {
	var txHash: String?
	var from: String?
	var to: String?
}
