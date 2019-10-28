//
//  ImpactProtocol.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 24/10/2019.
//  Copyright © 2019 Minter. All rights reserved.
//

import UIKit

protocol UIImpactFeedbackProtocol {

	var hardImpactFeedbackGenerator: UIImpactFeedbackGenerator { get }
	var lightImpactFeedbackGenerator: UIImpactFeedbackGenerator { get }

	func performLightImpact()
	func performHardImpact()
}

extension UIImpactFeedbackProtocol {

	func performLightImpact() {
		self.lightImpactFeedbackGenerator.prepare()
		self.lightImpactFeedbackGenerator.impactOccurred()
	}

	func performHardImpact() {
		self.hardImpactFeedbackGenerator.prepare()
		self.hardImpactFeedbackGenerator.impactOccurred()
	}
}
