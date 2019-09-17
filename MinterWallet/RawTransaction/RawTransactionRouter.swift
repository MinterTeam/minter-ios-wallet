//
//  RawTransactionRouter.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 16/09/2019.
//  Copyright © 2019 Minter. All rights reserved.
//

import Foundation

class RawTransactionRouter: BaseRouter {

	static var patterns: [String] {
		return ["tx"]
	}

	static func viewController(path: [String], param: [String : Any]) -> UIViewController? {
		return Storyboards.PIN.instantiateInitialViewController()
	}

}
