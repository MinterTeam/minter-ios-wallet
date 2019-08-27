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
