//
//  Decimal+Fractional.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 03/09/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import Foundation
import MinterCore

public extension Decimal {

	public var significantFractionalDecimalDigits: Int {
		return max(-exponent, 0)
	}

}

public extension Decimal {

	static func PIPComparableBalance(from amount: Decimal) -> Decimal? {

		let formatter = CurrencyNumberFormatter.decimalFormatter

		guard let amountString = formatter.string(from: amount as NSNumber),
			let normalizedAmount = Decimal(string:  amountString) else {
			return nil
		}

		return normalizedAmount * TransactionCoinFactorDecimal
	}

	func PIPToDecimal() -> Decimal {
		return self / TransactionCoinFactorDecimal
	}

	func decimalFromPIP() -> Decimal {
		return self * TransactionCoinFactorDecimal
	}

}
