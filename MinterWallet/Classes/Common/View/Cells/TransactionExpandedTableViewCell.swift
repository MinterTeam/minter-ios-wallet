//
//  TransactionExpandedTableViewCell.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 10/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import UIKit


class TransactionExpandedTableViewCell: BaseCell {
	
	weak var delegate: TransactionTableViewCellDelegate?
	
	//MARK: -

	@IBOutlet weak var fromLabel: UILabel!
	
	@IBOutlet weak var toLabel: UILabel!
	
	@IBOutlet weak var dateLabel: UILabel!
	
	@IBOutlet weak var timeLabel: UILabel!
	
	@IBOutlet weak var coinLabel: UILabel!
	
	@IBOutlet weak var amountLabel: UILabel!
	
	@IBAction func explorerButtonDidTap(_ sender: Any) {
		
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
		if let transactionItem = item as? TransactionTableViewCellItem {
			
			fromLabel.text = transactionItem.from
			toLabel.text = transactionItem.to
			dateLabel.text = transactionItem.date?.description
			timeLabel.text = transactionItem.date?.description
			coinLabel.text = transactionItem.coin
			amountLabel.text = "\(transactionItem.amount)"
			
		}
	}
	
}
