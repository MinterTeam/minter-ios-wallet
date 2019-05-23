//
//  TransactionTitleHelper.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 23/05/2019.
//  Copyright © 2019 Minter. All rights reserved.
//

import Foundation

class TransactionTitleHelper {

	class func title(from: String) -> String {
		if from.isValidAddress() || from.isValidPublicKey() {

			let indexStartOfText = from.index(from.startIndex, offsetBy: 7)
			let indexEndOfText = from.index(from.startIndex, offsetBy: from.count - 6)

			let substring1 = from[from.startIndex...indexStartOfText]
			let substring2 = from[indexEndOfText..<from.endIndex]

			return String(substring1) + "..." + String(substring2)
		}
		return from
	}

}
