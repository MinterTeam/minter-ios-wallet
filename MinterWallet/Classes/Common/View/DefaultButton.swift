//
//  DefaultButton.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 02/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import UIKit

@IBDesignable
class DefaultButton: UIButton {
	
	//MARK: -
	
	@IBInspectable var pattern: String? {
		didSet {
			self.updateAppearance()
		}
	}
	
	func updateAppearance() {
		if pattern == "transparent" {
			self.backgroundColor = .clear
			self.layer.borderWidth = 2.0
			self.layer.borderColor = UIColor.white.cgColor
			self.setTitleColor(.white, for: .normal)
		}
		else if pattern == "purple" {
			self.backgroundColor = UIColor(hex: 0x502EC2)
			self.setTitleColor(.white, for: .normal)
		}
		else {
			self.backgroundColor = .white
			self.setTitleColor(UIColor(hex: 0x502EC2), for: .normal)
		}
	}
	
	//MARK: -

	override func awakeFromNib() {
		self.titleLabel?.font = UIFont.boldFont(of: 14.0)
		self.layer.cornerRadius = 16.0
		self.updateAppearance()
	}

}
