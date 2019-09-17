//
//  DelegatedTableViewCell.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 07/06/2019.
//  Copyright © 2019 Minter. All rights reserved.
//

import UIKit
import RxSwift
import AlamofireImage

protocol DelegatedTableViewCellDelegate: class {
	func DelegatedTableViewCellDidTapCopy(cell: DelegatedTableViewCell)
}

class DelegatedTableViewCellItem: BaseCellItem {
	var title: String?
	var iconURL: URL?
	var publicKey: String?
}

class DelegatedTableViewCell: BaseCell {

	// MARK: -

	weak var delegate: DelegatedTableViewCellDelegate?

	// MARK: -

	@IBOutlet weak var validatorName: UILabel!
	@IBOutlet weak var validatorIcon: UIImageView!
	@IBOutlet weak var publicKey: UILabel!
	@IBOutlet weak var copyButton: TransactionAddressButton!

	// MARK: -

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

		self.validatorName.text = item.title ?? "Public Key".localized()
		self.publicKey.text = TransactionTitleHelper.title(from: item.publicKey ?? "")
		if let image = item.iconURL {
		self.validatorIcon.af_setImage(withURL: image,
																	 placeholderImage: UIImage(named: "delegateImage"),
																	 filter: nil,
																	 progress: { (progress) in
																		
		}, progressQueue: DispatchQueue.main,
			 imageTransition: UIImageView.ImageTransition.crossDissolve(0.1),
			 runImageTransitionIfCached: false) { (image) in
				
			}
		}

		copyButton.rx.tap.subscribe(onNext: { [weak self] (_) in
			self?.delegate?.DelegatedTableViewCellDidTapCopy(cell: self!)
		}).disposed(by: disposeBag)
	}
}
