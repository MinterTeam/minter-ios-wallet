//
//  Decimal+Fractional.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 03/09/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import Foundation

public extension Decimal {
	
	public var significantFractionalDecimalDigits: Int {
		return max(-exponent, 0)
	}
	
	
}

