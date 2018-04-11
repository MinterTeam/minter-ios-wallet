//
//  TransactionTableViewCell.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 09/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import UIKit


class TransactionTableViewCellItem : BaseCellItem {
	
	var title: String?
	var image: UIImage?
	var date: Date?
	var from: String?
	var to: String?
	var coin: String?
	var amount: Double?
	
}


class TransactionTableViewCell: BaseCell {

	@IBOutlet weak var title: UILabel!
	
	@IBOutlet weak var coinImage: UIImageView!
	
	@IBOutlet weak var amount: UILabel!
	
	@IBOutlet weak var coin: UILabel!
	
	
	//MARK: -
	
	override func awakeFromNib() {
		super.awakeFromNib()
	}

	override func setSelected(_ selected: Bool, animated: Bool) {
		super.setSelected(selected, animated: animated)
	}
	
	//MARK: -
	
	override func configure(item: BaseCellItem) {
		if let transaction = item as? TransactionTableViewCellItem {
			title.text = transaction.title
			coinImage.image = transaction.image
			amount.text = String(transaction.amount ?? 0)
			coin.text = transaction.coin
		}
	}

}
