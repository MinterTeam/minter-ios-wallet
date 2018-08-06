//
//  CoinsRouter.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 06/08/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import Foundation

class CoinsRouter : BaseRouter {
	
	static var patterns: [String] {
		return ["coins", "home", "balance"]
	}
	
	static func viewController(path: [String], param: [String : Any]) -> UIViewController? {
		return Storyboards.Coins.instantiateInitialViewController()
	}
	
	//MARK: -
	
	static func explorerViewController(url: URL) -> UIViewController {
		return BaseSafariViewController(url: url)
	}
	
}
