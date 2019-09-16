//
//  AddressTextView.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 12/09/2019.
//  Copyright © 2019 Minter. All rights reserved.
//

import Foundation

class AddressTextView: AutoGrowingTextView {
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		self.bounces = false
		self.showsVerticalScrollIndicator = false
	}
}
