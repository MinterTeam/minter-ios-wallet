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
	var selected: PickerTableViewCellPickerItem?
}

struct PickerTableViewCellPickerItem {
	var title: String?
	var object: Any?
}

protocol PickerTableViewCellDataSource: class {
	func pickerItems(for cell: PickerTableViewCell) -> [PickerTableViewCellPickerItem]
}

protocol PickerTableViewCellDelegate: class where Self: UIViewController {
	func didFinish(with item: PickerTableViewCellPickerItem?)
	
	func willShowPicker()
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
			let rightView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 10.0, height: 5.0))
			imageView.frame = CGRect(x: 0.0, y: 22.0, width: 10.0, height: 5.0)
			rightView.addSubview(imageView)
			rightView.isUserInteractionEnabled = false
			
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
	
	func updateRightViewMode() {
		if shouldShowPicker() {
			selectField.rightViewMode = .always
		}
		else {
			selectField.rightViewMode = .never
		}
	}
	
	//MARK: -
	
	override func configure(item: BaseCellItem) {
		super.configure(item: item)
		
		if let pickerItem = item as? PickerTableViewCellItem {
			self.label.text = pickerItem.title
			if let selected = pickerItem.selected {
				self.selectField.text = selected.title
			}
		}

	}
	
	//MARK: -
	
	func showPicker() {
		
		guard nil != delegate as? UIViewController else {
			return
		}
		
		delegate?.willShowPicker()
		
		guard let items = dataSource?.pickerItems(for: self) else {
			return
		}
		
		let data: [[String]] = [items.map({ (item) -> String in
			return item.title ?? ""
		})]
		
		let picker = McPicker(data: data)
		picker.toolbarButtonsColor = .white
		picker.toolbarDoneButtonColor = .white
		picker.toolbarBarTintColor = UIColor(hex: 0x4225A4)
		picker.toolbarItemsFont = UIFont.mediumFont(of: 16.0)
		picker.show { [weak self] (selected) in
			guard let coin = selected[0] else {
				return
			}
			self?.selectField.text = coin
			
			if let item = items.filter({ (item) -> Bool in
				return item.title == coin
			}).first {
				self?.delegate?.didFinish(with: item)
			}
		}
	}
	
	//MARK: - UITextFieldDelegate
	
	func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
		
		guard self.shouldShowPicker() else {
			return false
		}
		
		showPicker()
		
		return false
	}
	
	private func shouldShowPicker() -> Bool {
		return (dataSource?.pickerItems(for: self).count ?? 0) > 1
	}
	
}
