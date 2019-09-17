//
//  PINRouter.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 02/07/2019.
//  Copyright © 2019 Minter. All rights reserved.
//

import Foundation
import UIKit

class PINRouter: BaseRouter {

	static var patterns: [String] {
		return []
	}

	static func viewController(path: [String], param: [String : Any]) -> UIViewController? {
		return Storyboards.PIN.instantiateInitialViewController()
	}

	// MARK: -

	static func PINViewController(with viewModel: PINViewModel) -> PINViewController? {
		let viewController = Storyboards.PIN.instantiateInitialViewController()
		viewController.viewModel = viewModel
		return viewController
	}

	static func defaultPINViewController() -> PINViewController? {
		let viewModel = PINViewModel()
		viewModel.isBiometricEnabled = AppSettingsManager.shared.isBiometricsEnabled
		viewModel.desc = "Please enter a 4-digit PIN".localized()
		let viewController = Storyboards.PIN.instantiateInitialViewController()
		viewController.viewModel = viewModel
		return viewController
	}

}
