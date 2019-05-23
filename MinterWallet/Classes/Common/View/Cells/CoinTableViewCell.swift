//
//  TransactionTableViewCell.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 09/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import UIKit
import AlamofireImage

class CoinTableViewCellItem : BaseCellItem {
	var title: String?
	var image: UIImage?
	var imageURL: URL?
	var date: Date?
	var coin: String?
	var amount: Decimal?
}

class CoinTableViewCell: BaseCell {

	// MARK: -
	
	private let formatter = CurrencyNumberFormatter.coinFormatter

	// MARK: - IBOutlet

	@IBOutlet weak var title: UILabel!
	@IBOutlet weak var coinImage: UIImageView! {
		didSet {
			coinImage.makeBorderWithCornerRadius(radius: 17, borderColor: .clear, borderWidth: 2)
		}
	}
	@IBOutlet weak var amount: UILabel!
	@IBOutlet weak var coin: UILabel!
	@IBOutlet weak var amountLeadingConstraint: NSLayoutConstraint! {
		didSet {
			amountLeadingConstraints = amountLeadingConstraint
		}
	}
	var amountLeadingConstraints: NSLayoutConstraint?
	@IBOutlet weak var amountBottomConstraint: NSLayoutConstraint!
	@IBOutlet weak var coinImageWrapper: UIView! {
		didSet {
			coinImageWrapper.backgroundColor = .clear
			coinImageWrapper.layer.applySketchShadow(color: UIColor(hex: 0x000000, alpha: 0.2)!, alpha: 1, x: 0, y: 2, blur: 18, spread: 0)
		}
	}
	private var isShowingCoin = false
	@IBAction func didTapCell(_ sender: Any) {
		if self.title.frame.width > self.amount.frame.width {
			return
		}
		
		if !isShowingCoin {
			self.amountLeadingConstraint?.isActive = false
			self.amountLeadingConstraints?.isActive = false
			amount.adjustsFontSizeToFitWidth = true
			
			UIView.animate(withDuration: 0.2, animations: { [weak self] in
				self?.title.alpha = 0.0
				self?.layoutIfNeeded()
			}) { [weak self] (finished) in
				self?.isShowingCoin = true
			}
		} else {
				amount.adjustsFontSizeToFitWidth = false
				self.amountLeadingConstraint?.isActive = true
				UIView.animate(withDuration: 0.2, animations: { [weak self] in
					self?.title.alpha = 1.0
					self?.layoutIfNeeded()
				}) {  [weak self] (finished) in
					self?.isShowingCoin = false
				}
		}
	}
	
	//MARK: -
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}
	
	override func awakeFromNib() {
		super.awakeFromNib()
	}

	override func setSelected(_ selected: Bool, animated: Bool) {
		super.setSelected(selected, animated: animated)
	}
	
	//MARK: -
	
	override func configure(item: BaseCellItem) {
		if let transaction = item as? CoinTableViewCellItem {
			title.text = transaction.title
			coinImage.image = transaction.image
			if let url = transaction.imageURL {
				coinImage.af_setImage(withURL: url, filter: RoundedCornersFilter(radius: 17.0))
			}
			else {
				coinImage.image = transaction.image
			}
			
			amount.text = CurrencyNumberFormatter.formattedDecimal(with: transaction.amount ?? 0, formatter: formatter)
			coin.text = transaction.coin
		}
	}
	
	//MARK: -
	
	override func layoutSubviews() {
		super.layoutSubviews()
	}

}
