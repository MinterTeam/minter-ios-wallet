//
//  SendPayloadTableViewCell.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 12/09/2019.
//  Copyright © 2019 Minter. All rights reserved.
//

import UIKit

class SendPayloadTableViewCellItem: TextViewTableViewCellItem {}

class SendPayloadTableViewCell: TextViewTableViewCell {

	var borderLayer: CAShapeLayer?

	// MARK: - IBOutlets
	// MARK: -

	var maxLength = 110

	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}

	override func awakeFromNib() {
		super.awakeFromNib()
		activityIndicator?.backgroundColor = .clear
		textView.font = UIFont.mediumFont(of: 16.0)
		setDefault()
	}

	override func setSelected(_ selected: Bool, animated: Bool) {
		super.setSelected(selected, animated: animated)
	}

	func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
		return true
	}

	override func textViewDidEndEditing(_ textView: UITextView) {
		validateDelegate?.didValidateField(field: self)
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
