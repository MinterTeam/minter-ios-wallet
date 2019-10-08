//
//  UIColor+HEX.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 02/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import UIKit

extension UIColor {

	convenience init?(hex: UInt) {
		let red = CGFloat((hex & 0xFF0000) >> 16) / 255.0
		let green = CGFloat((hex & 0x00FF00) >> 8) / 255.0
		let blue = CGFloat(hex & 0x0000FF) / 255.0

		self.init(red: red, green: green, blue: blue, alpha: 1)
	}

	convenience init?(hex: UInt, alpha: CGFloat) {
		let red = CGFloat((hex & 0xFF0000) >> 16) / 255.0
		let green = CGFloat((hex & 0x00FF00) >> 8) / 255.0
		let blue = CGFloat(hex & 0x0000FF) / 255.0

		self.init(red: red, green: green, blue: blue, alpha: alpha)
	}
}
