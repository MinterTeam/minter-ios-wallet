//
//  String+Validation.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 19/06/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import Foundation

extension String {
	
	static func isUsernameValid(_ username: String) -> Bool {
		let usernameTest = NSPredicate(format:"SELF MATCHES %@", "^[a-zA-Z0-9_]{5,32}")
		return usernameTest.evaluate(with: username)
	}
	
	static func isPhoneValid(_ phone: String) -> Bool {
		let reg = "(\\+[0-9]+[\\- \\.]*)?([0-9][0-9\\- \\.]+[0-9])"        // +<digits><sdd>*
		let phoneTest = NSPredicate(format:"SELF MATCHES %@", reg)
		return phoneTest.evaluate(with: phone)
	}

}

