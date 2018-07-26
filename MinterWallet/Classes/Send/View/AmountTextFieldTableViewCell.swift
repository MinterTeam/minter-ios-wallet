//
//  AmountTextFieldTableViewCell.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 25/07/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import UIKit

class AmountTextFieldTableViewCellItem : TextFieldTableViewCellItem {
	
}

protocol AmountTextFieldTableViewCellDelegate : class {
	func didTapUseMax()
}


class AmountTextFieldTableViewCell : TextFieldTableViewCell {
	
	weak var amountDelegate: AmountTextFieldTableViewCellDelegate?
	
	override var state: State {
		didSet {
			switch state {
				
			case .valid:
				textField.layer.cornerRadius = 8.0
				textField.layer.borderWidth = 2
				textField.layer.borderColor = UIColor(hex: 0x4DAC4A)?.cgColor
				textField.rightView = textField.rightViewValid
				errorTitle.text = ""
				break
				
			case .invalid(let error):
				textField.layer.cornerRadius = 8.0
				textField.layer.borderWidth = 2
				textField.layer.borderColor = UIColor(hex: 0xEC373C)?.cgColor
				textField.rightView = textField.rightViewInvalid
				if nil != error {
					self.errorTitle.text = error
				}
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
	
	override func setInvalid(message: String?) {
		
		self.state = .invalid(error: message)
		
		if nil != message {
			self.errorTitle.text = message
		}
		
		self.textField.rightViewMode = .never
	}

	override func awakeFromNib() {
		super.awakeFromNib()
	}

	override func setSelected(_ selected: Bool, animated: Bool) {
		super.setSelected(selected, animated: animated)
	}
    
	@IBAction func didTapUseMax(_ sender: Any) {
		amountDelegate?.didTapUseMax()
	}
	
}
