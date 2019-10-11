//
//  UIApplication+AppDelegate.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 11/10/2019.
//  Copyright © 2019 Minter. All rights reserved.
//

import UIKit
import RxSwift
import RxAppState

extension UIApplication {
	static func realAppDelegate() -> AppDelegate? {
		guard
			let delegateProxy = UIApplication.shared.delegate as? RxApplicationDelegateProxy,
			let appDele = delegateProxy.forwardToDelegate() as? AppDelegate else {
			return nil
		}
		return appDele
	}
}
