//
//  LoginRouter.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 02/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import UIKit

class LoginRouter : BaseRouter {

	static var patterns: [String] {
		return ["login"]
	}

	static func viewController(path: [String], param: [String : Any]) -> UIViewController? {
		let vc = Storyboards.Login.instantiateViewController(withIdentifier: "LoginViewController")
		return vc
	}

}
