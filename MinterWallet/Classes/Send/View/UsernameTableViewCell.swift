//
//  UsernameTableViewCell.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 28/08/2019.
//  Copyright © 2019 Minter. All rights reserved.
//

import UIKit

class UsernameTableViewCellItem: TextViewTableViewCellItem {}

class UsernameTableViewCell: TextViewTableViewCell {

	var borderLayer: CAShapeLayer?

	// MARK: -

	var maxLength = 110

	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}

	override func awakeFromNib() {
		super.awakeFromNib()

		setDefault()
		activityIndicator?.backgroundColor = .clear
		textView.font = UIFont.mediumFont(of: 16.0)
	}

	@objc
	override func setValid() {
		self.textView?.superview?.layer.cornerRadius = 8.0
		self.textView?.superview?.layer.borderWidth = 2
		self.textView?.superview?.layer.borderColor = UIColor(hex: 0x4DAC4A)?.cgColor
		self.errorTitle.text = ""
	}

	@objc
	override func setInvalid(message: String?) {
		self.textView?.superview?.layer.cornerRadius = 8.0
		self.textView?.superview?.layer.borderWidth = 2
		self.textView?.superview?.layer.borderColor = UIColor.mainRedColor().cgColor
		
		if nil != message {
			self.errorTitle.text = message
		}
	}

	@objc
	override func setDefault() {
		self.textView?.superview?.layer.cornerRadius = 8.0
		self.textView?.superview?.layer.borderWidth = 2
		self.textView?.superview?.layer.borderColor = UIColor.mainGreyColor(alpha: 0.4).cgColor
		self.errorTitle.text = ""
	}
}
