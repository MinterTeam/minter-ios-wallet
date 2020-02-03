//
//  ReceiveRouter.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 06/08/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import UIKit

class ReceiveRouter: BaseRouter {

	static var patterns: [String] {
		return ["receive"]
	}

	static func viewController(path: [String], param: [String: Any]) -> UIViewController? {
    let viewModel = ReceiveViewModel(dependency: ReceiveViewModel.Dependency(accounts: Session.shared.accounts.asObservable()))
    let receiveVC = Storyboards.Receive.instantiateReceiveViewController()
    receiveVC.viewModel = viewModel
		return receiveVC
	}

	static func receiveViewController(viewModel: ReceiveViewModel) -> UIViewController? {
		let receiveVC = Storyboards.Receive.instantiateReceiveViewController()
		receiveVC.viewModel = viewModel
		receiveVC.tabBarItem = Self.receiveTabbarItem()
		return UINavigationController(rootViewController: receiveVC)
	}

	static func activityViewController(activities: [Any], sourceView: UIView) -> UIViewController {
		let activityVC = UIActivityViewController(activityItems: activities, applicationActivities: [])
		activityVC.popoverPresentationController?.sourceView = sourceView
		return activityVC
	}

	static func receiveTabbarItem() -> UITabBarItem {
		return UITabBarItem(title: "Receive".localized(),
												image: UIImage(named: "tabbarReceiveIcon"),
												selectedImage: UIImage(named: "tabbarReceiveIcon"))
	}
}
