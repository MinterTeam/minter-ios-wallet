//
//  UITextViewWorkaround.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 05.11.2019.
//  Copyright © 2019 Minter. All rights reserved.
//

import UIKit

@objc
class UITextViewWorkaround: NSObject {

	static func executeWorkaround() {
		if #available(iOS 13.2, *) {
		} else {
			let className = "_UITextLayoutView"
			let theClass = objc_getClass(className)
			if theClass == nil {
					let classPair: AnyClass? = objc_allocateClassPair(UIView.self, className, 0)
					objc_registerClassPair(classPair!)
			}
		}
	}
}
