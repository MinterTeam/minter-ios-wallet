//
//  UIColor+Sugar.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 21/05/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import Foundation

extension UIColor {
	func image(_ size: CGSize = CGSize(width: 1, height: 1)) -> UIImage {
		return UIGraphicsImageRenderer(size: size).image { rendererContext in
			self.setFill()
			rendererContext.fill(CGRect(x: 0, y: 0, width: size.width, height: size.height))
		}
	}
}
