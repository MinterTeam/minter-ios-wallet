//
//  SettingsRouter.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 24/10/2019.
//  Copyright © 2019 Minter. All rights reserved.
//

import UIKit

class SettingsRouter: BaseRouter {

	static var patterns: [String] {
		return ["settings"]
	}

	static func viewController(path: [String], param: [String: Any]) -> UIViewController? {
    let viewModel = SettingsViewModel()
    let settingsVC = Storyboards.Settings.instantiateSettingsViewController()
    settingsVC.viewModel = viewModel
    return settingsVC
	}

	static func settingsViewController(viewModel: SettingsViewModel) -> UIViewController? {
		let settingsVC = Storyboards.Settings.instantiateSettingsViewController()
		settingsVC.viewModel = viewModel
		settingsVC.tabBarItem = Self.settingsTabbarItem()
		return UINavigationController(rootViewController: settingsVC)
	}

	static func settingsTabbarItem() -> UITabBarItem {
		return UITabBarItem(title: "Settings".localized(),
												image: UIImage(named: "tabbarSettingsIcon"),
												selectedImage: UIImage(named: "tabbarSettingsIcon"))
	}
}
