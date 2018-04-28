//
//  GrowingDefaultTextView.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 27/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import UIKit
import GrowingTextView

class GrowingDefaultTextView: GrowingTextView {

	override func awakeFromNib() {
		super.awakeFromNib()
		
		self.layer.cornerRadius = 8.0
		self.layer.borderWidth = 2
		self.layer.borderColor = UIColor(hex: 0x929292, alpha: 0.4)?.cgColor
	}

}
