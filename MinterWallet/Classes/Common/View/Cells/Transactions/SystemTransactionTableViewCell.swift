//
//  SystemTransactionTableViewCell.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 26/08/2019.
//  Copyright © 2019 Minter. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

class SystemTransactionTableViewCellItem: TransactionCellItem {
	var title: String?
	var type: String?
	var image: UIImage?
	var date: String?
	var time: String?
  var amount: String?
}

class SystemTransactionTableViewCell: BaseTransactionCell {

	// MARK: -

	@IBOutlet weak var mainImageViewWrapper: UIView! {
		didSet {
			mainImageViewWrapper.layer
				.applySketchShadow(color: UIColor(hex: 0x000000,
																					alpha: 0.2)!,
													 alpha: 1,
													 x: 0,
													 y: 2,
													 blur: 18,
													 spread: 0)
		}
	}
	@IBOutlet weak var mainTitleLabel: UILabel!
	@IBOutlet weak var mainImageView: UIImageView! {
		didSet {
			mainImageView.makeBorderWithCornerRadius(radius: 17.0,
																							 borderColor: .clear,
																							 borderWidth: 2.0)
		}
	}
	@IBOutlet weak var timeLabel: UILabel!
	@IBOutlet weak var dateLabel: UILabel!
	@IBOutlet weak var explorerButton: DefaultButton!
  @IBOutlet weak var amountLabel: UILabel!

	// MARK: -

	override func setSelected(_ selected: Bool, animated: Bool) {
		super.setSelected(selected, animated: animated)
	}

	// MARK: -

	override func configure(item: BaseCellItem) {
		super.configure(item: item)

		defer {
			self.setNeedsUpdateConstraints()
			self.setNeedsLayout()
			self.layoutIfNeeded()
		}

		identifier = item.identifier
		explorerButton.rx.tap.subscribe(onNext: { [weak self] (_) in
			self?.delegate?.didTapExplorerButton(cell: self!)
		}).disposed(by: disposeBag)

		if let item = item as? SystemTransactionTableViewCellItem {
			self.mainImageView?.image = item.image
			self.mainTitleLabel.text = item.title
			self.dateLabel.text = item.date
			self.timeLabel.text = item.time
      self.amountLabel.text = item.amount
		}
	}

}
