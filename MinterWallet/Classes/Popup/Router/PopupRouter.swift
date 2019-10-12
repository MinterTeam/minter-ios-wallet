//
//  PopupRouter.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 04/06/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import Foundation

class PopupRouter: BaseRouter {

	// MARK: - BaseRouter

	static var patterns: [String] = []

	static func viewController(path: [String], param: [String : Any]) -> UIViewController? {
		return nil
	}

	// MARK: -

	class func sentPopupViewCointroller(viewModel: SentPopupViewModel) -> SentPopupViewController? {
		let viewController = Storyboards.Popup.instantiateSentPopupViewController()
		viewController.viewModel = viewModel
		return viewController
	}

	class func confirmPopupViewController(viewModel: ConfirmPopupViewModel) -> ConfirmPopupViewController? {
		let viewController = Storyboards.Popup.instantiateConfirmPopupViewController()
		viewController.viewModel = viewModel
		return viewController
	}
}
