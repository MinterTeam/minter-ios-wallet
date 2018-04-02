//
//  String+Localized.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 02/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import Foundation

extension String {
	func localized(_ comment: String = "") -> String {
		return NSLocalizedString(self, comment: comment)
	}
}
