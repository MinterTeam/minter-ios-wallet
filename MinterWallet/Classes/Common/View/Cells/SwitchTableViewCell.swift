//
//  SwitchTableViewCell.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 16/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import UIKit

class SwitchTableViewCellItem : BaseCellItem {
	
	var title: String = ""
	
}


class SwitchTableViewCell: BaseCell {
	
	//MARK: - IBOutelet

	@IBOutlet weak var label: UILabel!
	
	@IBOutlet weak var `switch`: UISwitch!
	
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
		
		if let item = item as? SwitchTableViewCellItem {
			self.label.text = item.title
		}
	}

}
