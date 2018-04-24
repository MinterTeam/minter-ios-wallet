//
//  DisclosureTableViewCell.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 19/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import UIKit


class DisclosureTableViewCellItem : BaseCellItem {
	
	var title: String?
	
	var placeholder: String?
	
	var value: String?
	
}


class DisclosureTableViewCell: BaseCell {
	
	//MARK: - IBOutlet
	
	@IBOutlet weak var title: UILabel!
	
	@IBOutlet weak var value: UILabel!
	
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
		
		if let disclosureItem = item as? DisclosureTableViewCellItem {
			
			if let val = disclosureItem.value {
				value.text = val
				value.textColor = .black
			}
			else {
				value.text = disclosureItem.placeholder ?? ""
				value.textColor = UIColor(hex: 0x929292)
			}
			
			title.text = disclosureItem.title ?? ""
			
			
		}
	}

}
