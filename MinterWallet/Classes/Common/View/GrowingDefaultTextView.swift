//
//  GrowingDefaultTextView.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 27/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import UIKit
import SwiftValidator

class GrowingDefaultTextView: AutoGrowingTextView {

	//MARK: - IBOutlets
	//MARK: -

//	public var validationText: String {
//		return self.text ?? ""
//	}

	override func awakeFromNib() {
		super.awakeFromNib()

		setDefault()
	}

	func setValid() {
		setDefault()
	}

	func setInvalid() {
		self.layer.cornerRadius = 8.0
		self.layer.borderWidth = 2
		self.layer.borderColor = UIColor.mainRedColor().cgColor
	}

	// MARK: -

	func setDefault() {
		self.layer.cornerRadius = 8.0
		self.layer.borderWidth = 2
		self.layer.borderColor = UIColor.mainGreyColor(alpha: 0.4).cgColor
	}

	// MARK: -

	override func layoutSubviews() {
		super.layoutSubviews()
	}

}
