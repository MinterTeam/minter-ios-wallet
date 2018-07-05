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
	var amount: Double?
}


class CoinTableViewCell: BaseCell {
	
	//MARK: -
	
	let formatter = CurrencyNumberFormatter.coinFormatter
	
	//MARK: - IBOutlets

	@IBOutlet weak var title: UILabel!
	
	@IBOutlet weak var coinImage: UIImageView! {
		didSet {
			coinImage.makeBorderWithCornerRadius(radius: 17, borderColor: .white, borderWidth: 2)
		}
	}
	
	@IBOutlet weak var amount: UILabel!
	
	@IBOutlet weak var coin: UILabel!
	
	@IBOutlet weak var coinImageWrapper: UIView! {
		didSet {
			coinImageWrapper.layer.cornerRadius = 17
			coinImageWrapper.layer.applySketchShadow(color: UIColor(hex: 0x000000, alpha: 0.2)!, alpha: 1, x: 0, y: 2, blur: 18, spread: 0)
		}
	}
	
	//MARK: -
	
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
				coinImage.af_setImage(withURL: url)
			}
			else {
				coinImage.image = transaction.image
			}
			amount.text = formatter.string(from: (transaction.amount ?? 0) as NSNumber)
			coin.text = transaction.coin
		}
	}
	
	//MARK: -
	
	override func layoutSubviews() {
		super.layoutSubviews()
	}

}
