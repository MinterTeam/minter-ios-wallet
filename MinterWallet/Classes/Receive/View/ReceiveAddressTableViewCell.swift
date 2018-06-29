//
//  ReceiveAddressTableViewCell.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 26/06/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import UIKit


class ReceiveAddressTableViewCellItem : BaseCellItem {
	var address: String?
}



class ReceiveAddressTableViewCell: BaseCell {
	
	//MARK: -
	
	@IBOutlet weak var addressLabel: UILabel!
	
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
		
		if let item = item as? ReceiveAddressTableViewCellItem {
			addressLabel.text = item.address
		}
		
	}

}
