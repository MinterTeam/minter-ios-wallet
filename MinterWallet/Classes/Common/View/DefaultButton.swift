//
//  DefaultButton.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 02/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import UIKit

class DefaultButton: UIButton {

	override func awakeFromNib() {
		self.setTitleColor(UIColor(hex: 0x502EC2), for: .normal)
		self.layer.cornerRadius = 16.0
	}

}
