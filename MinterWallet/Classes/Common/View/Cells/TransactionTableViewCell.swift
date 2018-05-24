//
//  TransactionTableViewCell.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 09/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import UIKit


class TransactionTableViewCellItem : BaseCellItem {
	
	var txHash: String?
	var title: String?
	var image: UIImage?
	var date: Date?
	var from: String?
	var to: String?
	var coin: String?
	var amount: Double?
	var expandable: Bool?
}

protocol TransactionTableViewCellDelegate : class {
	func didTapExpandedButton(cell: TransactionTableViewCell)
}


class TransactionTableViewCell: ExpandableCell {
	
	//MARK: -
	
	let formatter = CurrencyNumberFormatter.transactionFormatter
	let dateFormatter = TransactionDateFormatter.transactionDateFormatter
	let timeFormatter = TransactionDateFormatter.transactionTimeFormatter
	
	weak var delegate: TransactionTableViewCellDelegate?
	
	//MARK: - IBOutlets

	@IBOutlet weak var title: UILabel!
	
	@IBOutlet weak var coinImage: UIImageView!
	
	@IBOutlet weak var amount: UILabel!
	
	@IBOutlet weak var coin: UILabel!
	
	@IBOutlet weak var fromAddressLabel: UILabel!
	
	@IBOutlet weak var toAddressLabel: UILabel!
	
	@IBOutlet weak var expandedAmountLabel: UILabel!
	
	@IBOutlet weak var coinLabel: UILabel!
	
	@IBOutlet weak var dateLabel: UILabel!
	
	@IBOutlet weak var timeLabel: UILabel!
	
	
	//MARK: -
	
	var shadowLayer = CAShapeLayer()
	
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
		if let transaction = item as? TransactionTableViewCellItem {
			title.text = transaction.title
			coinImage.image = transaction.image
			amount.text = amountText(amount: transaction.amount ?? 0)
			amount.textColor = ((transaction.amount ?? 0) > 0) ? UIColor(hex: 0x35B65C) : .black
			
			fromAddressLabel.text = transaction.from
			toAddressLabel.text = transaction.to
			expandedAmountLabel.text = amountText(amount: transaction.amount ?? 0)
			coinLabel.text = transaction.coin
			dateLabel.text = dateFormatter.string(from: transaction.date ?? Date())
			timeLabel.text = timeFormatter.string(from: transaction.date ?? Date())
			
			coin.text = transaction.coin
			expandable = transaction.expandable ?? false
		}
	}
	
	private func amountText(amount: Double) -> String {
		return formatter.string(from: amount as NSNumber) ?? ""
	}
	
	//MARK: -
	
	@IBAction func didTapExpandedButton(_ sender: Any) {
		delegate?.didTapExpandedButton(cell: self)
	}
	
	//MARK: -
	
	func dropShadow() {
		shadowLayer.removeFromSuperlayer()
		shadowLayer.frame = coinImage.frame
		shadowLayer.path = UIBezierPath(roundedRect: coinImage.bounds, cornerRadius: 17.0).cgPath
		shadowLayer.shadowOpacity = 1.0
		shadowLayer.shadowRadius = 18.0
		shadowLayer.masksToBounds = false
		shadowLayer.shadowColor = UIColor(hex: 0x000000)?.cgColor
		shadowLayer.shadowOffset = CGSize(width: 2.0, height: 2.0)
		shadowLayer.opacity = 0.2
		shadowLayer.shouldRasterize = true
		shadowLayer.rasterizationScale = UIScreen.main.scale
		layer.insertSublayer(shadowLayer, at: 0)
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		
		dropShadow()
	}

}
