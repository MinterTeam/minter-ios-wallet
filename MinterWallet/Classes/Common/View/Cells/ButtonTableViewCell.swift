//
//  BUttonTableViewCell.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 10/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import UIKit


protocol ButtonTableViewCellDelegate: class {
	func ButtonTableViewCellDidTap(_ cell: ButtonTableViewCell)
}


class ButtonTableViewCellItem : BaseCellItem {

	var title: String?
	
	var buttonPattern: String?

}


class ButtonTableViewCell: BaseCell {

	@IBOutlet weak var button: DefaultButton!
	
	//MARK: - IBActions
	
	@IBAction func buttonDidTap(_ sender: Any) {
		delegate?.ButtonTableViewCellDidTap(self)
	}
	
	//MARK: -
	
	weak var delegate: ButtonTableViewCellDelegate?
	
	//MARK: -
	
	override func awakeFromNib() {
		super.awakeFromNib()
	}

	override func setSelected(_ selected: Bool, animated: Bool) {
		super.setSelected(selected, animated: animated)
	}
	
	//MARK: -
	
	override func configure(item: BaseCellItem) {
		if let buttonItem = item as? ButtonTableViewCellItem {
			button?.setTitle(buttonItem.title, for: .normal)
			button?.pattern = buttonItem.buttonPattern
		}
	}
    
}
