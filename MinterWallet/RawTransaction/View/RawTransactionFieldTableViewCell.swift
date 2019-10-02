//
//  RawTransactionFieldTableViewCell.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 01/10/2019.
//  Copyright © 2019 Minter. All rights reserved.
//

import UIKit
import RxSwift
import QuartzCore

class RawTransactionFieldTableViewCellItem: BaseCellItem {
	var title: String?
	var value: String?
}

class RawTransactionFieldTableViewCell: BaseCell {

	// MARK: - IBOutlet

	@IBOutlet weak var fieldTitle: UILabel!
	@IBOutlet weak var valueWrapperView: UIView!
	@IBOutlet weak var fieldValue: UILabel!

	// MARK: -

	override func awakeFromNib() {
		super.awakeFromNib()
	}

	override func setSelected(_ selected: Bool, animated: Bool) {
		super.setSelected(selected, animated: animated)
	}

	// MARK: - Configurable

	override func configure(item: BaseCellItem) {
		guard let item = item as? RawTransactionFieldTableViewCellItem else {
			return
		}
		self.fieldTitle.text = item.title
		self.fieldValue.text = item.value
	}
}
