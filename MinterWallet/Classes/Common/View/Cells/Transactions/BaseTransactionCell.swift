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
	@IBOutlet var payloadBottomConstraint: NSLayoutConstraint!

	// MARK: -

	override func configure(item: BaseCellItem) {

		guard let transaction = item as? TransactionCellItem else {
			return
		}

		payloadText.text = transaction.payload
		payloadTitle.isHidden = !(transaction.payload != nil && transaction.payload != "")
		payloadBottomConstraint?.isActive = (transaction.payload != nil && transaction.payload != "")
		setNeedsUpdateConstraints()
	}

}
