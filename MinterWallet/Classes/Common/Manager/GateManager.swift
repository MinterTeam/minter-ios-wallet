//
//  GateManager.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 23/01/2019.
//  Copyright © 2019 Minter. All rights reserved.
//

import Foundation
import Alamofire
import MinterCore

var MinterGateBaseURLString = "https://gate.minter.network"

enum GateManagerError : Error {
	case wrongResponse
}

enum MinterGateAPIURL {

	case nonce(address: String)
	case minGasPrice
	case estimateTXComission
	case estimateCoinSell
	case estimateCoinSellAll
	case estimateCoinBuy
	case send

	func url() -> URL {
		switch self {

		case .nonce(let address):
			return URL(string: MinterGateBaseURLString + "/api/v1/nonce/" + address)!

		case .estimateCoinBuy:
			return URL(string: MinterGateBaseURLString + "/api/v1/estimate/coin-buy")!

		case .estimateCoinSell:
			return URL(string: MinterGateBaseURLString + "/api/v1/estimate/coin-sell")!
			
		case .estimateCoinSellAll:
			return URL(string: MinterGateBaseURLString + "/api/v1/estimate/coin-sell-all")!

		case .estimateTXComission:
			return URL(string: MinterGateBaseURLString + "/api/v1/estimate/tx-commission")!

		case .minGasPrice:
			return URL(string: MinterGateBaseURLString + "/api/v1/min-gas")!

		case .send:
			return URL(string: MinterGateBaseURLString + "/api/v1/transaction/push")!

		}
	}
}

class GateManager : BaseManager {

	// MARK: -

	static let shared = GateManager(httpClient: APIClient())

	// MARK: -

	func minGasPrice(completion: ((Int?, Error?) -> ())?) {

		let url = MinterGateAPIURL.minGasPrice.url()

		self.httpClient.getRequest(url, parameters: nil) { (response, error) in
			if let resp = response.data as? [String : Any],
				let gas = resp["gas"] as? String,
				let gasInt = Int(gas) {
				completion?(gasInt, nil)
			} else {
				completion?(nil, GateManagerError.wrongResponse)
			}
		}
	}

	/// Method retreives transaction count
	///
	/// - Parameters:
	///   - address: "Mx" prefixed address (e.g. Mx184ac726059e43643e67290666f7b3195093f870)
	///   - completion: method which will be called after request finished
	public func nonce(for address: String, completion: ((Decimal?, Error?) -> ())?) {

		let url = MinterGateAPIURL.nonce(address: "Mx" + address.stripMinterHexPrefix()).url()

		self.httpClient.getRequest(url, parameters: nil) { (response, error) in

			var count: Decimal?
			var err: Error?

			defer {
				completion?(count, err)
			}

			guard nil == error else {
				err = error
				return
			}

			if let data = response.data as? [String : Any],
				let cnt = data["nonce"] as? String {
				count = Decimal(string: cnt)
			} else {
				err = GateManagerError.wrongResponse
			}
		}
	}
	
	/// Method retreives estimate coin buy
	///
	/// - Parameters:
	///   - coinFrom: coin to sell (e.g. MNT)
	///   - coinTo: coin to buy (e.g. BELTCOIN)
	///		- value: value to calculate estimates for
	///   - completion: method which will be called after request finished
	public func estimateCoinBuy(coinFrom: String, coinTo: String, value: Decimal, completion: ((Decimal?, Decimal?, Error?) -> ())?) {

		let url = MinterGateAPIURL.estimateCoinBuy.url()

		self.httpClient.getRequest(url, parameters: ["coinToBuy" : coinTo,
																								 "coinToSell" : coinFrom,
																								 "valueToBuy" : value]) { (response, error) in

			var willPay: Decimal?
			var com: Decimal?
			var err: Error?

			defer {
				completion?(willPay, com, err)
			}

			guard nil == error else {
				err = error
				return
			}

			if let data = response.data as? [String : String],
				let pay = data["will_pay"],
				let commission = data["commission"] {

					willPay = Decimal(string: pay)
					com = Decimal(string: commission)
			} else {
				err = GateManagerError.wrongResponse
			}
		}
	}

	/// Method retreives estimate coin sell
	///
	/// - Parameters:
	///   - coinFrom: coin to sell (e.g. MNT)
	///   - coinTo: coin to buy (e.g. BELTCOIN)
	///		- value: value to calculate estimates for
	///   - completion: method which will be called after request finished
	public func estimateCoinSell(coinFrom: String,
															 coinTo: String,
															 value: Decimal,
															 completion: ((Decimal?, Decimal?, Error?) -> ())?) {

		let url = MinterGateAPIURL.estimateCoinSell.url()

		self.httpClient.getRequest(url, parameters: ["coinToBuy" : coinTo, "coinToSell" : coinFrom, "valueToSell" : value]) { (response, error) in

			var willGet: Decimal?
			var com: Decimal?
			var err: Error?

			defer {
				completion?(willGet, com, err)
			}

			guard nil == error else {
				err = error
				return
			}

			if let data = response.data as? [String : String],
				let get = data["will_get"],
				let commission = data["commission"] {

					willGet = Decimal(string: get)
					com = Decimal(string: commission)
			} else {
				err = GateManagerError.wrongResponse
			}
		}
	}

	/// Method retreives estimate coin sell
	///
	/// - Parameters:
	///   - coinFrom: coin to sell (e.g. MNT)
	///   - coinTo: coin to buy (e.g. BELTCOIN)
	///		- value: value to calculate estimates for
	///		- gasPrice: gas price
	///   - completion: method which will be called after request finished
	public func estimateCoinSellAll(coinFrom: String,
																	coinTo: String,
																	value: Decimal,
																	gasPrice: Int,
																	completion: ((Decimal?, Decimal?, Error?) -> ())?) {

		let url = MinterGateAPIURL.estimateCoinSellAll.url()

		self.httpClient.getRequest(url,
															 parameters: ["coinToBuy": coinTo,
																						"coinToSell": coinFrom,
																						"valueToSell": value,
																						"gasPrice" : gasPrice]) { (response, error) in

			var willGet: Decimal?
			var com: Decimal?
			var err: Error?

			defer {
				completion?(willGet, com, err)
			}

			guard nil == error else {
				err = error
				return
			}

			if let data = response.data as? [String : String],
				let get = data["will_get"],
				let commission = data["commission"] {
					willGet = Decimal(string: get)
					com = Decimal(string: commission)
			} else {
				err = GateManagerError.wrongResponse
			}
		}
	}

	/// Method retreives estimate comission for raw transaction
	///
	/// - Parameters:
	///   - rawTx: encoded raw transaction
	///   - completion: method which will be called after request finished
	func estimateTXCommission(for rawTx: String,
														completion: ((Decimal?, Error?) -> ())?) {

		let url = MinterGateAPIURL.estimateTXComission.url()

		self.httpClient.getRequest(url, parameters: ["transaction" : rawTx]) { (response, error) in

			var com: Decimal?
			var err: Error?

			defer {
				completion?(com, err)
			}

			guard nil == error else {
				err = error
				return
			}

			if let data = response.data as? [String : String], let commission = data["commission"] {
				com = Decimal(string: commission)
			} else {
				err = GateManagerError.wrongResponse
			}
		}
	}

	/// Method sends raw transaction to the Minter network
	///
	/// - Parameters:
	///   - rawTransaction: encoded transaction
	///   - completion: method which will be called after request finished
	public func sendRawTransaction(rawTransaction: String, completion: ((String?, Error?) -> ())?) {

		let url = MinterGateAPIURL.send.url()

		self.httpClient.postRequest(url, parameters: ["transaction" : rawTransaction]) { (response, error) in

			var tx: String?
			var err: Error?

			defer {
				completion?(tx, err)
			}

			guard nil == error else {
				err = error
				return
			}

			if let resp = response.data as? [String : Any],
				let hash = resp["hash"] as? String {
				tx = hash
			} else {
				err = GateManagerError.wrongResponse
			}
		}
	}

}
