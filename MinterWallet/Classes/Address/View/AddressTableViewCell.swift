//
//  AddressTableViewCell.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 26/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import UIKit
import NotificationBannerSwift

class AddressTableViewCellItem: BaseCellItem {
	var address: String?
	var buttonTitle: String?
}

class AddressTableViewCell: BaseCell {

	// MARK: - IBOutlet/IBAction

	@IBOutlet weak var addressLabel: UILabel!
	@IBOutlet weak var actionButton: UIButton!
	@IBAction func didTapActionButton(_ sender: Any) {
		SoundHelper.playSoundIfAllowed(type: .click)
		AnalyticsHelper.defaultAnalytics.track(event: .addressesCopyButton, params: nil)
		UIPasteboard.general.string = addressLabel.text
		let banner = NotificationBanner(title: "Copied".localized(),
																		subtitle: nil,
																		style: .info)
		banner.show()
	}

	// MARK: -

	override func awakeFromNib() {
		super.awakeFromNib()
		let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapAddress))
		self.contentView.addGestureRecognizer(tapGesture)
	}

	override func setSelected(_ selected: Bool, animated: Bool) {
		super.setSelected(selected, animated: animated)
	}

	@objc func didTapAddress() {}

	// MARK: - BaseCell

	override func configure(item: BaseCellItem) {
		if let addressItem = item as? AddressTableViewCellItem {
			let address = "Mx" + (addressItem.address?.stripMinterHexPrefix() ?? "").lowercased()
			addressLabel.text = address
			actionButton.setTitle(addressItem.buttonTitle, for: .normal)
		}
	}
}
