//
//  TextFieldTableViewCell.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 03/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import UIKit
import SwiftValidator


class TextFieldTableViewCellItem : BaseCellItem {
	var title: String = ""
	var isSecure: Bool = false
	var rules: [Rule] = []
	var prefix: String?
	var state: TextFieldTableViewCell.State?
	var error: String?
	var value: String?
}


class TextFieldTableViewCell: BaseCell, ValidatableCellProtocol {
	
	//MARK: -
	
	enum State {
		case valid
		case invalid
		case `default`
	}
	
	var state: State = .default {
		didSet {
			switch state {

			case .valid:
				textField.layer.cornerRadius = 8.0
				textField.layer.borderWidth = 2
				textField.layer.borderColor = UIColor(hex: 0x4DAC4A)?.cgColor
				textField.rightView = textField.rightViewValid
				textField.rightViewMode = .always
				errorTitle.text = ""
				break

			case .invalid:
				textField.layer.cornerRadius = 8.0
				textField.layer.borderWidth = 2
				textField.layer.borderColor = UIColor(hex: 0xEC373C)?.cgColor
				textField.rightView = textField.rightViewInvalid
				textField.rightViewMode = .always
				break

			default:
				textField.layer.cornerRadius = 8.0
				textField.layer.borderWidth = 2
				textField.layer.borderColor = UIColor(hex: 0x929292, alpha: 0.4)?.cgColor
				textField.rightView = UIView()
				textField.rightViewMode = .never
				errorTitle.text = ""
				break
			}
		}
	}

	//MARK: -
	
	@IBOutlet weak var title: UILabel!
	
	@IBOutlet weak var errorTitle: UILabel!
	
	@IBOutlet weak var textField: ValidatableTextField!
	
	//MARK: - Validators
	
	var validationText: String {
		return textField.text ?? ""
	}
	
	var validator = Validator()
	
	var validatorRules: [Rule] = [] {
		didSet {
			validator.registerField(self.textField, errorLabel: self.errorTitle, rules: validatorRules)
		}
	}
	
	//MARK: - BaseCell
	
	override func configure(item: BaseCellItem) {
		super.configure(item: item)
		
		if let item = item as? TextFieldTableViewCellItem {
			title.text = item.title
			textField.isSecureTextEntry = item.isSecure
			textField.prefixText = item.prefix
			textField.text = item.value
			state = item.state ?? .default
			validatorRules = item.rules
			errorTitle.text = item.error
		}
	}
	
	//MARK: -

	override func awakeFromNib() {
		super.awakeFromNib()
		
		state = .default
	}
	
	override func prepareForReuse() {
		super.prepareForReuse()
		
		state = .default
		
		layoutIfNeeded()
	}

	override func setSelected(_ selected: Bool, animated: Bool) {
		super.setSelected(selected, animated: animated)
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
	}
	
	//MARK: -
	
	func startEditing() {
		self.textField.becomeFirstResponder()
	}
	
	//MARK: - ValidatableCellProtocol
	
	weak var validateDelegate: ValidatableCellDelegate?
	
	func setValid() {
		self.state = .valid
		self.errorTitle.text = ""
	}
	
	func setInvalid(message: String?) {
		self.state = .invalid
		if nil != message {
			self.errorTitle.text = message
		}
	}
	
	func setDefault() {
		self.state = .default
		self.errorTitle.text = ""
	}

}

extension TextFieldTableViewCell : UITextFieldDelegate {
	
	func textFieldDidEndEditing(_ textField: UITextField) {
		
		validateDelegate?.didValidateField(field: self)
		
		validateDelegate?.validate(field: self, completion: {
			print("Validation has been completed")
		})
		
	}
	
}
