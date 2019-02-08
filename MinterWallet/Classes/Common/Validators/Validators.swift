//
//  Validators.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 06/02/2019.
//  Copyright © 2019 Minter. All rights reserved.
//

import Foundation
import MinterCore

class BaseValidator {}

class AmountValidator : BaseValidator {
	
	class func isValid(amount: Decimal) -> Bool {
		return amount >= 1/TransactionCoinFactorDecimal || amount == 0
	}
}

class CoinValidator : BaseValidator {
	
	class func isValid(coin: String?) -> Bool {
		return (coin?.count ?? 0) >= 3
	}
	
}
