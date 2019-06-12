//
//  DelegatedTableViewCell.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 07/06/2019.
//  Copyright © 2019 Minter. All rights reserved.
//

import UIKit
import RxSwift

protocol DelegatedTableViewCellDelegate: class {
	func DelegatedTableViewCellDidTapCopy(cell: DelegatedTableViewCell)
}

class DelegatedTableViewCellItem: BaseCellItem {
	var publicKey: String?
}

class DelegatedTableViewCell: BaseCell {

	// MARK: -

	weak var delegate: DelegatedTableViewCellDelegate?

	// MARK: -

	@IBOutlet weak var publicKey: UILabel!
	@IBOutlet weak var copyButton: TransactionAddressButton!

	override func awakeFromNib() {
		super.awakeFromNib()
	}

	override func setSelected(_ selected: Bool, animated: Bool) {
		super.setSelected(selected, animated: animated)
	}

	// MARK: -

	override func configure(item: BaseCellItem) {
		guard let item = item as? DelegatedTableViewCellItem else {
			return
		}

		self.publicKey.text = TransactionTitleHelper.title(from: item.publicKey ?? "")

		copyButton.rx.tap.subscribe(onNext: { [weak self] (_) in
			self?.delegate?.DelegatedTableViewCellDidTapCopy(cell: self!)
		}).disposed(by: disposeBag)

	}

}
