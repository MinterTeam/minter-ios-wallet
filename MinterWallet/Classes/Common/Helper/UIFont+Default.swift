//
//  UIFont+Default.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 02/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import UIKit


let defaultFontNameRegular = "Ubuntu-R"
let defaultFontNameMedium = "Ubuntu-M"
let defaultFontNameBold = "Ubuntu-B"
let defaultFontNameCoursive = "Ubuntu-C"
let defaultFontNameLight = "Ubuntu-L"


extension UIFont {

	static func defaultFont(of size: CGFloat) -> UIFont {
		return UIFont(name: defaultFontNameRegular, size: size)!
	}
	
	static func boldFont(of size: CGFloat) -> UIFont {
		return UIFont(name: defaultFontNameBold, size: size)!
	}
	
	static func mediumFont(of size: CGFloat) -> UIFont {
		return UIFont(name: defaultFontNameMedium, size: size)!
	}
	
	static func lightFont(of size: CGFloat) -> UIFont {
		return UIFont(name: defaultFontNameLight, size: size)!
	}
	
	static func coursiveFont(of size: CGFloat) -> UIFont {
		return UIFont(name: defaultFontNameCoursive, size: size)!
	}

}
