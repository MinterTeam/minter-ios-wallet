//
//  TransactionAddressButton.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 23/05/2019.
//  Copyright © 2019 Minter. All rights reserved.
//

import UIKit

class TransactionAddressButton: UIButton {

	override var isHighlighted: Bool {
		didSet {
			
			UIView.animate(withDuration: 0.5) {
				self.alpha = self.isHighlighted ? 0.5 : 1
			}
			
			
//			UIView.animate(withDuration: 2.25,
//										 delay: 0,
//										 options: [.beginFromCurrentState, .allowUserInteraction],
//										 animations: {
//
//				self.alpha = self.isHighlighted ? 0.5 : 1
//				print(self.isHighlighted)
//			}, completion: nil)
		}
	}

}
