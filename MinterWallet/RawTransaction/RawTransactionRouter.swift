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
    var nonce: BigUInt?
    var gasPrice: BigUInt?
    var gasCoin: String = Coin.baseCoin().symbol!
    var type: RawTransactionType = .sendCoin
    var txData: Data?
    var payload: String?
    var userData: [String: Any]? = [:]

    guard let tx = param["d"] as? String else {
      return nil
    }
    var newTx = tx.data(using: .utf8) ?? Data()

    if let data = Data(base64URLEncoded: tx) {
      newTx = data
    }
    if
      let rlpItem = RLP.decode(newTx),
      let content = rlpItem[0]?.content {

			switch content {
			case .noItem:
				return nil

			case .list(let items, _, _):
				if items.count >= 3 {//shortened version
					guard
						let typeData = items[safe: 0]?.data,
						let txDataData = RLP.decode(items[safe: 1]?.data ?? Data())?.data,
						let payloadData = items[safe: 2]?.data
					else { return nil }

					let nonceData = items[safe: 3]?.data ?? Data()
					let gasPriceData = items[safe: 4]?.data ?? Data()
					let gasCoinData = items[safe: 5]?.data ?? Data()

					let nonceValue = BigUInt(nonceData)
					nonce = nonceValue > 0 ? nonceValue : nil

					let gasPriceValue = BigUInt(gasPriceData)
					gasPrice = gasPriceValue > 0 ? gasPriceValue : nil
					if let newGasCoin = String(coinData: gasCoinData) {
						gasCoin = (newGasCoin == "") ? Coin.baseCoin().symbol! : newGasCoin
						guard gasCoin.isValidCoin() else {
							return nil
						}
					}
					let typeBigInt = BigUInt(typeData)
					guard let txType = RawTransactionType.type(with: typeBigInt) else {
						return nil
					}
					type = txType
					txData = txDataData
					payload = String(data: payloadData, encoding: .utf8)
				}
				break
			case .data(let _):
				return nil
			}

			if let password = param["p"] as? String {
				userData?["p"] = password
			}
      return viewController(nonce: nonce,
                            gasPrice: gasPrice,
                            gasCoin: gasCoin,
                            type: type,
                            data: txData,
                            payload: payload,
                            serviceData: nil,
                            signatureType: nil,
                            userData: userData)
    }
		return nil
	}

	static func rawTransactionViewController(with url: URL) -> UIViewController? {
		if url.path.contains("tx") {
      // new format
      if url.params()["d"] == nil {
        let txData = String(url.path.split(separator: "/").last ?? "")
        var params = url.params()
        params["d"] = txData
        return RawTransactionRouter.viewController(path: ["tx"], param: params)
      }
			return RawTransactionRouter.viewController(path: ["tx"], param: url.params())
		}
		return nil
	}

  static func viewController(
    nonce: BigUInt?,
    gasPrice: BigUInt?,
    gasCoin: String?,
    type: RawTransactionType,
    data: Data?,
    payload: String?,
    serviceData: Data?,
    signatureType: Data?,
    userData: [String: Any]?
  ) -> UIViewController? {
    let viewModel: RawTransactionViewModel
    do {
      let dependency = RawTransactionViewModel.Dependency(account: RawTransactionViewModelAccount(),
                                                          gate: GateManager.shared)
      viewModel = try RawTransactionViewModel(
        dependency: dependency,
        account: Session.shared.accounts.value.first,
        nonce: nonce,
        gasPrice: gasPrice,
        gasCoin: gasCoin,
        type: type,
        data: data,
        payload: payload,
        serviceData: nil,
        signatureType: nil,
        userData: userData)
    } catch {
      return nil
    }

    let viewController = Storyboards.RawTransaction.instantiateInitialViewController()
    viewController.navigationBar.barStyle = .black
    (viewController.viewControllers.first as? RawTransactionViewController)?.viewModel = viewModel
    return viewController
  }

}
