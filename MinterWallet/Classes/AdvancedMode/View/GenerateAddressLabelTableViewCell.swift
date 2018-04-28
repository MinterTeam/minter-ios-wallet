//
//  GenerateAddressLabelTableViewCell.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 27/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import UIKit

class GenerateAddressLabelTableViewCellItem : BaseCellItem {
	
	var text: String?
	
}


class GenerateAddressLabelTableViewCell: BaseCell {
	
	//MARK: - IBOutlet
	
	@IBOutlet weak var label: UILabel!
	
	//MARK: -

	override func awakeFromNib() {
		super.awakeFromNib()
	}

	override func setSelected(_ selected: Bool, animated: Bool) {
		super.setSelected(selected, animated: animated)
	}
	
	//MARK: - Configurable
	
	override func configure(item: BaseCellItem) {
		super.configure(item: item)
		
		if let labelItem = item as? GenerateAddressLabelTableViewCellItem {
			label.text = labelItem.text
		}
	}

}
