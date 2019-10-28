//
//  ConvertRouter.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 28/10/2019.
//  Copyright © 2019 Minter. All rights reserved.
//

import UIKit

class ConvertRouter: BaseRouter {

	static var patterns: [String] {
		return ["convert"]
	}

	static func viewController(path: [String], param: [String: Any]) -> UIViewController? {
		return Storyboards.Convert.instantiateRootConvertViewController()
	}

	static func convertViewController() -> UIViewController? {
		return Storyboards.Convert.instantiateRootConvertViewController()
	}
}
