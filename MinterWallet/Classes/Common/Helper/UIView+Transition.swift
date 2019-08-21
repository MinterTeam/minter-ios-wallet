//
//  UIView+Transition.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 21/08/2019.
//  Copyright © 2019 Minter. All rights reserved.
//

import Foundation

extension UIView {
	func pushTransition(_ duration:CFTimeInterval) {
		let animation:CATransition = CATransition()
		animation.timingFunction = CAMediaTimingFunction(name:
			kCAMediaTimingFunctionEaseInEaseOut)
		animation.type = kCATransitionPush
		animation.subtype = kCATransitionFromTop
		animation.duration = duration
		layer.add(animation, forKey: kCATransitionPush)
	}
}
