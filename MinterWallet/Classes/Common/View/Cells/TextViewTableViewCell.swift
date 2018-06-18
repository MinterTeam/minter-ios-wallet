//
//  TextViewTableViewCell.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 06/06/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import UIKit
import SwiftValidator
//import GrowingTextView


protocol TextViewTableViewCellDelegate: class {
	func heightDidChange(cell: TextViewTableViewCell)
}


class TextViewTableViewCellItem : BaseCellItem {
	
	var title: String?
	
	var rules: [Rule] = []
	
}


class TextViewTableViewCell : BaseCell, AutoGrowingTextViewDelegate, ValidatableCellProtocol {
	
	
	//MARK: -
	
	weak var delegate: TextViewTableViewCellDelegate?
	
	weak var validateDelegate: ValidatableCellDelegate?

	//MARK: - IBOutlets
	
	@IBOutlet weak var title: UILabel!
	
	@IBOutlet weak var errorTitle: UILabel!
	
	@IBOutlet weak var textView: GrowingDefaultTextView! {
		didSet {
			textView.contentInset = UIEdgeInsets(top: 10, left: 16, bottom: 6, right: 16)
		}
	}
	
	//MARK: - Validators
	
	var validationText: String {
		return textView.text ?? ""
	}
	
	var validator = Validator()
	
	var validatorRules: [Rule] = [] {
		didSet {
			validator.registerField(self.textView, errorLabel: self.errorTitle, rules: validatorRules)
		}
	}
	
	//MARK: -
	
	override func awakeFromNib() {
		super.awakeFromNib()
	}

	override func setSelected(_ selected: Bool, animated: Bool) {
		super.setSelected(selected, animated: animated)
	}
	
	//MARK: - BaseCell
	
	override func configure(item: BaseCellItem) {
		super.configure(item: item)
		
		if let item = item as? TextViewTableViewCellItem {
			self.title.text = item.title
			self.validatorRules = item.rules
		}
	}
	
	func textViewDidChangeHeight(_ textView: AutoGrowingTextView, height: CGFloat) {
		delegate?.heightDidChange(cell: self)
	}
	
	//MARK: - Validate
	
	func setValid() {
		self.textView.layer.cornerRadius = 8.0
		self.textView.layer.borderWidth = 2
		self.textView.layer.borderColor = UIColor(hex: 0x4DAC4A)?.cgColor
		self.errorTitle.text = ""
	}
	
	func setInvalid(message: String?) {
		self.textView.layer.cornerRadius = 8.0
		self.textView.layer.borderWidth = 2
		self.textView.layer.borderColor = UIColor(hex: 0xEC373C)?.cgColor
		
		if nil != message {
			self.errorTitle.text = message
		}
	}
	
	func setDefault() {
		self.textView.layer.cornerRadius = 8.0
		self.textView.layer.borderWidth = 2
		self.textView.layer.borderColor = UIColor(hex: 0x929292, alpha: 0.4)?.cgColor
		self.errorTitle.text = ""
	}
	
	func validate() {
		validator.validate { (result) in
			result.forEach({ (validation) in
//				validation.1.errorLabel?.text =
				self.setInvalid(message: validation.1.errorMessage)
			})
		}
	}

}

extension TextViewTableViewCell : UITextViewDelegate {
	
	func textViewDidEndEditing(_ textView: UITextView) {
		self.validate()
	}

}
