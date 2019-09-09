//
//  UsernameTableViewCell.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 28/08/2019.
//  Copyright © 2019 Minter. All rights reserved.
//

import UIKit

class AddressTextView: AutoGrowingTextView {
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		self.bounces = false
		self.showsVerticalScrollIndicator = false
	}
}

class UsernameTableViewCellItem: TextViewTableViewCellItem {}

protocol UsernameTableViewCellDelegate: class {
	func didTapScanButton(cell: UsernameTableViewCell?)
}

class UsernameTableViewCell: TextViewTableViewCell {
	
	var borderLayer: CAShapeLayer?

	// MARK: - IBOutlets

	@IBOutlet weak var scanButton: UIButton!
	@IBAction func scanButtonDidTap(_ sender: Any) {
		addressDelegate?.didTapScanButton(cell: self)
	}

	// MARK: -

	var maxLength = 110

	weak var addressDelegate: UsernameTableViewCellDelegate?

	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}

	override func awakeFromNib() {
		super.awakeFromNib()

		activityIndicator?.backgroundColor = .clear
		textView.font = UIFont.mediumFont(of: 16.0)
	}

	override func setSelected(_ selected: Bool, animated: Bool) {
		super.setSelected(selected, animated: animated)
	}

	func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {

		if text != "" && text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) == "" {
			return false
		}

		var txtAfterUpdate = textView.text ?? ""
		txtAfterUpdate = (txtAfterUpdate as NSString).replacingCharacters(in: range, with: text).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)

		if text.contains(UIPasteboard.general.string ?? "") {
//			textViewScroll.layoutSubviews()
			return true
		}
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
		self.textView?.superview?.layer.borderColor = UIColor(hex: 0xEC373C)?.cgColor
		
		if nil != message {
			self.errorTitle.text = message
		}
	}
	
	@objc
	override func setDefault() {
		self.textView?.superview?.layer.cornerRadius = 8.0
		self.textView?.superview?.layer.borderWidth = 2
		self.textView?.superview?.layer.borderColor = UIColor(hex: 0x929292, alpha: 0.4)?.cgColor
		self.errorTitle.text = ""
	}
	
}
