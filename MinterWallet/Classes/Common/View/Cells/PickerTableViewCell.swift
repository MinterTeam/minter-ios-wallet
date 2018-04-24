//
//  PickerTableViewCell.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 16/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import UIKit
import McPicker


class PickerTableViewCellItem : BaseCellItem {
	var title: String?
}


protocol PickerTableViewCellDataSource: class {
	
}

protocol PickerTableViewCellDelegate: class where Self: UIViewController {
	
}


class PickerTableViewCell: BaseCell, UITextFieldDelegate {
	
	//MARK: -
	
	weak var dataSource: PickerTableViewCellDataSource?
	
	weak var delegate: PickerTableViewCellDelegate?
	
	//MARK: -

	@IBOutlet weak var label: UILabel!
	
	@IBOutlet weak var selectField: ValidatableTextField! {
		didSet {
			
			let imageView = UIImageView(image: UIImage(named: "textFieldSelectIcon"))
			let rightView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 5))
			imageView.frame = CGRect(x: 0, y: 22, width: 10, height: 5)
			rightView.addSubview(imageView)
			
			selectField.layer.cornerRadius = 8.0
			selectField.layer.borderWidth = 2
			selectField.layer.borderColor = UIColor(hex: 0x929292, alpha: 0.4)?.cgColor
			selectField.rightView = rightView
			selectField.rightViewMode = .always
		}
	}
	
	
	//MARK: -
	
	override func awakeFromNib() {
		super.awakeFromNib()
	}

	override func setSelected(_ selected: Bool, animated: Bool) {
		super.setSelected(selected, animated: animated)
	}
	
	//MARK: -
	
	override func configure(item: BaseCellItem) {
		super.configure(item: item)
		
		if let pickerItem = item as? PickerTableViewCellItem {
			self.label.text = pickerItem.title
		}
	}
	
	//MARK: -
	
	func showPicker() {
		
		guard let vc = delegate as? UIViewController else {
			return
		}
		
		let data: [[String]] = [["BIP", "SOL", "COIN", "TestCoin"]]
		let picker = McPicker(data: data)
		picker.toolbarButtonsColor = .white
		picker.toolbarDoneButtonColor = .white
		picker.toolbarBarTintColor = UIColor(hex: 0x4225A4)
		picker.toolbarItemsFont = UIFont.mediumFont(of: 16.0)
		picker.show { (selected) in
			guard let coin = selected[0] else {
				return
			}
			self.selectField.text = coin
		}
	}
	
	//MARK: - UITextFieldDelegate
	
	func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
		
		showPicker()
		
		return false
	}
	
}
