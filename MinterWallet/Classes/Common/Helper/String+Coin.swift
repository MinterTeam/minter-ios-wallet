//
//  String+Coin.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 07/08/2019.
//  Copyright © 2019 Minter. All rights reserved.
//

import Foundation

extension String {

	func transformToCoinName() -> String {
		return self.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
	}
	
	init?(coinData: Data) {
		self.init(data: coinData, encoding: .utf8)
		self = self.replacingOccurrences(of: "\0", with: "")
	}
}
