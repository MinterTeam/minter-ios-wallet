//
//  BaseTransactionCell.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 20/08/2019.
//  Copyright © 2019 Minter. All rights reserved.
//

import Foundation

class BaseTransactionCell: ExpandableCell {

	// MARK: -

	@IBOutlet weak var payloadText: UILabel!
	@IBOutlet weak var payloadTitle: UILabel!
	@IBOutlet weak var payloadBottomConstraint: NSLayoutConstraint!

	// MARK: -

	override func configure(item: BaseCellItem) {

		guard let transaction = item as? TransactionCellItem else {
			return
		}

		if self.reuseIdentifier?.lowercased().contains("convert") ?? false {
			
		}

		print(transaction.payload)
//		if transaction.payload != nil && transaction.payload != "" {
			payloadText.text = transaction.payload
			payloadTitle.isHidden = !(transaction.payload != nil && transaction.payload != "")
			payloadBottomConstraint?.isActive = (transaction.payload != nil && transaction.payload != "")
//		} else {
//			payloadText.text = ""
//			payloadTitle.isHidden = true
//			payloadBottomConstraint?.isActive = false
//		}
		setNeedsUpdateConstraints()
		layoutIfNeeded()
	}

	override func prepareForReuse() {
		super.prepareForReuse()

		if self.reuseIdentifier?.lowercased().contains("convert") ?? false {
			
		}

	}

}
