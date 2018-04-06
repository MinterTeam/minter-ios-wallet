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
}


class TextFieldTableViewCell: BaseCell {
	
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
			}
		}
	}

	//MARK: -
	
	@IBOutlet weak var title: UILabel!
	
	@IBOutlet weak var errorTitle: UILabel!
	
	@IBOutlet weak var textField: ValidatableTextField!
	
	//MARK: - Validators
	
	private let validator = Validator()
	
	var validatorRules: [Rule] = [] {
		didSet {
			validator.registerField(self.textField, rules: validatorRules)
		}
	}
	
	func validationSuccessful() {
		// submit the form
	}
	
	func validationFailed(errors: [(Validatable, ValidationError)]) {
		for (field, error) in errors {
//			if let field = field as? UITextField {
//				field.layer.borderColor = UIColor.redColor().CGColor
//				field.layer.borderWidth = 1.0
//			}
//			error.errorLabel?.text = error.errorMessage // works if you added labels
//			error.errorLabel?.isHidden = false
		}
	}
	
	//MARK: - BaseCell
	
	override func configure(item: BaseCellItem) {
		if let item = item as? TextFieldTableViewCellItem {
			title.text = item.title
			textField.isSecureTextEntry = item.isSecure
			textField.prefixText = item.prefix
		}
//		layoutIfNeeded()
	}
	
	//MARK: -

	override func awakeFromNib() {
		super.awakeFromNib()
		
		state = .default
	}
	
	override func prepareForReuse() {
		super.prepareForReuse()
		
		layoutIfNeeded()
	}

	override func setSelected(_ selected: Bool, animated: Bool) {
		super.setSelected(selected, animated: animated)
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
	}
	
	//MARK: -
	
	
}
