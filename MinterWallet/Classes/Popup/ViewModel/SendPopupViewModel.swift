//
//  SendPopupViewModel.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 18/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import UIKit

class SendPopupViewModel: PopupViewModel {

	// MARK: -

	private var formatter = CurrencyNumberFormatter.coinFormatter

	// MARK: -

	override init() {
		super.init()
		formatter.maximumFractionDigits = 100
	}

	// MARK: -

	var amount: Decimal?

	var coin: String?

	var amountString: String? {
		return formatter.string(from: (amount ?? 0) as NSNumber)
	}

	var avatarImageURL: URL?
	
	var avatarImage: UIImage?

	var username: String?

	var buttonTitle: String?

	var cancelTitle: String?
}
