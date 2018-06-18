//
//  SessionHelper.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 16/05/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import Foundation
import MinterCore
import MinterMy

class SessionHelper {
	
	class func reloadAccounts() {
		Session.shared.loadAccounts()
	}
	
	class func setFirstAccount(account: Account) {
	
//		var acc = Session.shared.accounts.value.filter { (acc) -> Bool in
//			acc.address == account.address
//		}.first
//		
//		guard let idx = Session.shared.accounts.value.index(where: { (acc) -> Bool in
//			return acc.address == account.address
//		}) else {
//			return
//		}
		
//		let acc1 = Session.shared.accounts.value[safe: idx]
//		Session.shared.accounts.value.remove(at: idx)
//		Session.shared.accounts.value.insert(acc1!, at: 0)
		
//
//		acc?.isMain = true
//
//
//		Session.shared.accounts.value = Session.shared.accounts.value
//			.sorted(by: { (acc1, acc2) -> Bool in
//			return acc1.isMain && !acc2.isMain
//		})
	}
	
	class func set(accessToken: String?, refreshToken: String?, user: User?) {
		
		guard nil != accessToken, nil != refreshToken, nil != user else {
			return
		}
		
		if nil != accessToken {
			Session.shared.setAccessToken(accessToken!)
		}
		
		if nil != refreshToken {
			Session.shared.setRefreshToken(refreshToken!)
		}
		
		if nil != user {
			Session.shared.setUser(user!)
		}
	}
	
	
}

