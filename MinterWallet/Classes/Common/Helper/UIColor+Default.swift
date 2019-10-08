//
//  UIColor+Default.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 08/10/2019.
//  Copyright © 2019 Minter. All rights reserved.
//

import UIKit

extension UIColor {

	static func mainColor(alpha: CGFloat = 1) -> UIColor {
		return UIColor(hex: 0x502EC2, alpha: alpha)!
	}

	static func mainGreenColor(alpha: CGFloat = 1) -> UIColor {
		return UIColor(hex: 0x35B65C, alpha: alpha)!
	}

	static func mainRedColor(alpha: CGFloat = 1) -> UIColor {
		return UIColor(hex: 0xEC373C, alpha: alpha)!
	}

	static func mainGreyColor(alpha: CGFloat = 1) -> UIColor {
		return UIColor(hex: 0x929292, alpha: alpha)!
	}
}
