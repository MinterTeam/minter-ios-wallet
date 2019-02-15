//
//  GenerateAddressSeedTableViewCell.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 27/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import UIKit
import NotificationBannerSwift

class GenerateAddressSeedTableViewCellItem : BaseCellItem {

	var phrase: String?

}


class GenerateAddressSeedTableViewCell: BaseCell {
	
	//MARK: - IBOutlets
	
	@IBOutlet weak var seedLabel: UILabel!

	@IBAction func copyBtnDidTap(_ sender: Any) {
		
		SoundHelper.playSoundIfAllowed(type: .click)
		
		UIPasteboard.general.string = seedLabel.text
		
		let banner = NotificationBanner(title: "Copied".localized(), subtitle: nil, style: .info)
		banner.show()
	}

	//MARK: -

	override func awakeFromNib() {
		super.awakeFromNib()
	}

	override func setSelected(_ selected: Bool, animated: Bool) {
		super.setSelected(selected, animated: animated)
	}

	//MARK: -

	override func configure(item: BaseCellItem) {
		super.configure(item: item)
		
		if let seedItem = item as? GenerateAddressSeedTableViewCellItem {
			seedLabel.text = seedItem.phrase
		}
	}

}
