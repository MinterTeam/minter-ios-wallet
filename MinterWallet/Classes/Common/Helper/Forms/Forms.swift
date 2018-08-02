//
//  Forms.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 13/07/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import Foundation

class LoginForm {
	
	class func isUsernameValid(username: String) -> Bool {
		let usernameTest = NSPredicate(format:"SELF MATCHES %@", "^[a-zA-Z0-9_]{5,16}")
		return usernameTest.evaluate(with: username)
	}
	
	class func isPasswordValid(password: String) -> Bool {
		return password.count >= 6
	}
	
}


class RegistrationForm : LoginForm {

	class func isEmailValid(email: String) -> Bool {
		return email.isValidEmail()
	}
	
}

