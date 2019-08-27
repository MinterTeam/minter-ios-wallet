//
//  Session+.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 20/08/2019.
//  Copyright © 2019 Minter. All rights reserved.
//

import Foundation

extension Session {

	func hasAddress(address: String) -> Bool {
		return Session.shared.accounts.value.contains(where: { (account) -> Bool in
			account.address.stripMinterHexPrefix().lowercased() == address.stripMinterHexPrefix().lowercased()
		})
	}
}
