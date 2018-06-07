//
//  String+RawTransactionAddress.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 29/05/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import Foundation

extension String {
	
	func isValidAddress() -> Bool {
		
		if self.stripMinterHexPrefix().count == 40 {
			return true
		}
		return false
	}

}
