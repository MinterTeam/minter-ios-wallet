//
//  SettingsSwitchTableViewCell.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 23/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import UIKit

class SettingsSwitchTableViewCell: SwitchTableViewCell {

	override func awakeFromNib() {
		super.awakeFromNib()

		self.label.font = UIFont.defaultFont(of: 14.0)
	}

	override func setSelected(_ selected: Bool, animated: Bool) {
		super.setSelected(selected, animated: animated)
	}

	override func configure(item: BaseCellItem) {
		super.configure(item: item)
	}
}
