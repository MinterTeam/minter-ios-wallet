//
//  SendRouter.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 24/10/2019.
//  Copyright © 2019 Minter. All rights reserved.
//

import UIKit

class SendRouter: BaseRouter {

	static var patterns: [String] {
		return ["send"]
	}

	static func viewController(path: [String], param: [String: Any]) -> UIViewController? {
		return Storyboards.Send.instantiateInitialViewController()
	}

	static func sendViewController(viewModel: SendViewModel) -> UIViewController? {
		let sendVC = Storyboards.Send.instantiateSendViewController()
		sendVC.viewModel = viewModel
		sendVC.tabBarItem = Self.sendTabbarItem()
		return UINavigationController(rootViewController: sendVC)
	}

	static func sendTabbarItem() -> UITabBarItem {
		return UITabBarItem(title: "Send".localized(),
												image: UIImage(named: "tabbarSendIcon"),
												selectedImage: UIImage(named: "tabbarSendIcon"))
	}
}
