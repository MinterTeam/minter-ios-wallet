//
//  String+Email.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 09/06/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import Foundation


extension String {
	
	func isValidEmail() -> Bool {
		let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,6}"
		let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
		let result = emailTest.evaluate(with: self)
		return result
	}
}
