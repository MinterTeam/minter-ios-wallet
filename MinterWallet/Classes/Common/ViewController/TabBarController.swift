//
//  TabBarController.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 02/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import UIKit

class TabBarController: UITabBarController {
	
	//MARK: -

	override func viewDidLoad() {
		super.viewDidLoad()
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
	}
	
	//MARK: -
	
	override var preferredStatusBarStyle: UIStatusBarStyle {
		return .lightContent
	}
	
	override var childViewControllerForStatusBarStyle: UIViewController? {
		let vc = self.viewControllers?[safe: self.selectedIndex]
		let navVC = vc as? UINavigationController
		guard nil == navVC else {
			return navVC?.visibleViewController
		}
		
		return vc
	}

}
