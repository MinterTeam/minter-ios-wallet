//
//  Tabbar.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 24/05/2019.
//  Copyright © 2019 Minter. All rights reserved.
//

import UIKit

class SafeAreaFixTabBar: UITabBar {
	
	var oldSafeAreaInsets = UIEdgeInsets.zero
	
	@available(iOS 11.0, *)
	override func safeAreaInsetsDidChange() {
		super.safeAreaInsetsDidChange()
		
		if oldSafeAreaInsets != safeAreaInsets {
			oldSafeAreaInsets = safeAreaInsets
			
			invalidateIntrinsicContentSize()
			superview?.setNeedsLayout()
			superview?.layoutSubviews()
		}
	}
	
	override func sizeThatFits(_ size: CGSize) -> CGSize {
		var size = super.sizeThatFits(size)
		if #available(iOS 11.0, *) {
			let bottomInset = safeAreaInsets.bottom
			if bottomInset > 0 && size.height < 50 && (size.height + bottomInset < 90) {
				size.height += bottomInset
			}
		}
		return size
	}
	
	override var frame: CGRect {
		get {
			return super.frame
		}
		set {
			var tmp = newValue
			if let superview = superview, tmp.maxY !=
				superview.frame.height {
				tmp.origin.y = superview.frame.height - tmp.height
			}
			
			super.frame = tmp
		}
	}
}
