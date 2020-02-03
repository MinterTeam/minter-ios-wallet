//
//  TransactionsRouter.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 24/10/2019.
//  Copyright © 2019 Minter. All rights reserved.
//

import Foundation

class TransactionsRouter: BaseRouter {

	static var patterns: [String] {
		return ["transactions"]
	}

	static func viewController(path: [String], param: [String: Any]) -> UIViewController? {
    let coinsVC = Storyboards.Transactions.instantiateTransactionsViewController()
    coinsVC.viewModel = TransactionsViewModel()
    return coinsVC
	}

	static func transactionsViewController(viewModel: TransactionsViewModel) -> UIViewController? {
		let coinsVC = Storyboards.Transactions.instantiateTransactionsViewController()
		coinsVC.viewModel = viewModel
		return coinsVC
	}
}
