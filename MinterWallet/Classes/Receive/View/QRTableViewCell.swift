//
//  QRTableViewCell.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 26/06/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import UIKit
import QRCode
import SVProgressHUD

class QRTableViewCellItem : BaseCellItem {
	
	var string: String?
	
}

protocol QRTableViewCellDelegate: class {
	func QRTableViewCellDidTapCopy(cell: QRTableViewCell)
}

class QRTableViewCell: BaseCell {
	
	weak var delegate: QRTableViewCellDelegate?
	
	//MARK: - 

	@IBOutlet weak var qrImageView: UIImageView!
	
	@IBOutlet weak var copyBtn: UIButton!
	
	@IBAction func copyButtonDidTap(_ sender: Any) {
		delegate?.QRTableViewCellDidTapCopy(cell: self)
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
