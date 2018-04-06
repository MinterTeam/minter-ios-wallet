//
//  UIViewController+TopMost.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 04/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import UIKit

extension UIViewController {
	
	static public func stars_topMostController(base: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
		if let nav = base as? UINavigationController {
			return topMostController(base: nav.visibleViewController)
		}
		if let tab = base as? UITabBarController {
			if let selected = tab.selectedViewController {
				return topMostController(base: selected)
			}
		}

		if let tab = base as? TabBarController {
			let idx = tab.selectedIndex
			if let vc = tab.viewControllers?[safe: idx] {
				return topMostController(base: vc)
			}
		}
		
//		if let rootVC = base as? RootViewController, let childVC = rootVC.childViewControllers.first {
//			return topMostController(base: childVC)
//		}
		
		if let presented = base?.presentedViewController {
			return topMostController(base: presented)
		}
		return base
	}
	
}

extension UIViewController {
	@objc static public func topMostController(base: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
		if let nav = base as? UINavigationController {
			return topMostController(base: nav.visibleViewController)
		}
		if let tab = base as? UITabBarController {
			if let selected = tab.selectedViewController {
				return topMostController(base: selected)
			}
		}
		if let presented = base?.presentedViewController {
			return topMostController(base: presented)
		}
		return base
	}
	
	@objc public func showAlertErrorFromApi(_ error: String) {
		let alertView = UIAlertView(title: "Ошибка сервера", message: error, delegate: nil, cancelButtonTitle: "Ok")
		alertView.show()
	}
}
