//
//  RawTransactionRouter.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 16/09/2019.
//  Copyright © 2019 Minter. All rights reserved.
//

import Foundation
import MinterCore
import BigInt

class RawTransactionRouter: BaseRouter {

	static var patterns: [String] {
		return ["tx"]
	}

	static func viewController(path: [String], param: [String: Any]) -> UIViewController? {

		if let tx = param["tx"] as? String {
			var nonce: BigUInt
			var chainId: BigUInt
			var gasPrice: BigUInt
			var gasCoin: String = Coin.baseCoin().symbol!
			var type: RawTransactionType = .sendCoin
			var txData: Data?
			var payload: String?
			var serviceData: Data?
			var signatureType: Data?

			guard let rlpItem = RLP.decode(tx) else {
				return nil
			}

			switch rlpItem[0]!.content {
			case .noItem:
				break

			case .list(let items, let count, let data):
				guard items.count == 9 || items.count == 10 else { return nil }

				nonce = BigUInt(items[0].data!)
				chainId = BigUInt(items[1].data!)
				gasPrice = BigUInt(items[2].data!)
				if let newGasCoin = String(data: items[3].data!, encoding: .utf8)?
					.replacingOccurrences(of: "\0", with: "") {
					gasCoin = newGasCoin
				}
				let typeBigInt = BigUInt(items[4].data!)
				guard let txType = RawTransactionType.type(with: typeBigInt) else {
					return nil
				}
				type = txType
				txData = RLP.decode(items[5].data!)!.data!
				payload = String(data: items[6].data!, encoding: .utf8)
				serviceData = items[7].data!
				signatureType = items[8].data!
				break

			case .data(let data):
				break
			}

			let viewModel = RawTransactionViewModel(gasCoin: gasCoin,
																							type: type,
																							data: txData,
																							payload: payload,
																							serviceData: serviceData,
																							signatureType: signatureType)

			let viewController = Storyboards.RawTransaction.instantiateInitialViewController()
			(viewController.viewControllers.first as? RawTransactionViewController)?.viewModel = viewModel
			return viewController
		}
		return nil
	}
}
