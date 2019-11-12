//
//  CoinsRouter.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 06/08/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import Foundation

class CoinsRouter: BaseRouter {

	static var patterns: [String] {
		return ["coins", "home", "balance"]
	}

	static func viewController(path: [String], param: [String: Any]) -> UIViewController? {
		return Storyboards.Coins.instantiateInitialViewController()
	}

	static func explorerViewController(url: URL) -> UIViewController {
		return BaseSafariViewController(url: url)
	}

	static func coinsViewController(viewModel: CoinsViewModel) -> UIViewController? {
		let coinsVC = Storyboards.Coins.instantiateCoinsViewController()
		coinsVC.viewModel = viewModel
		coinsVC.tabBarItem = Self.coinsTabbarItem()
		return UINavigationController(rootViewController: coinsVC)
	}

	static func coinsTabbarItem() -> UITabBarItem {
		return UITabBarItem(title: "Coins".localized(),
												image: UIImage(named: "circle"),
												selectedImage: UIImage(named: "circle"))
	}
}
