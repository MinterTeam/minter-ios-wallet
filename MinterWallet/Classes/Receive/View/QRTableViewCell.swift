//
//  QRTableViewCell.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 26/06/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import UIKit
import QRCode

class QRTableViewCellItem : BaseCellItem {
	
	var string: String?
	
}

class QRTableViewCell: BaseCell {
	
	//MARK: - 

	@IBOutlet weak var qrImageView: UIImageView!
	
	@IBOutlet weak var copyBtn: UIButton!
	
	@IBAction func copyButtonDidTap(_ sender: Any) {
		
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
		
		if let item = item as? QRTableViewCellItem, let string = item.string {
			let qr = QRCode(string)
			qrImageView.image = qr?.image
			
		}
	}

}
