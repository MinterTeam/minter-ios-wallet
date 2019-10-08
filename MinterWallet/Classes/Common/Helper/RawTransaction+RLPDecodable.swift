//
//  RawTransaction+RLPDecodable.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 04/10/2019.
//  Copyright © 2019 Minter. All rights reserved.
//

import Foundation
import MinterCore
import BigInt

class RawTransactionDecoder {

	typealias RawTransactionDecoderResult = (
		nonce: BigUInt?,
		chainId: BigUInt?,
		gasPrice: BigUInt?,
		gasCoin: String,
		type: RawTransactionType,
		txData: Data?,
		payload: String?,
		serviceData: Data?,
		signatureType: Data?
	)

	static func decode(_ tx: Data) -> RawTransactionDecoderResult? {
		var nonce: BigUInt?
		var chainId: BigUInt?
		var gasPrice: BigUInt?
		var gasCoin: String = Coin.baseCoin().symbol!
		var type: RawTransactionType = .sendCoin
		var txData: Data?
		var payload: String?
		var serviceData: Data?
		var signatureType: Data?

		guard let rlpItem = RLP.decode(tx) else { return nil }

		switch rlpItem[0]!.content {
		case .noItem:
			break

		case .list(let items, let count, let data):
			//Full tx version
			if items.count == 9 || items.count == 10 {
				guard
					let nonceData = items[0].data,
					let chainIdData = items[1].data,
					let gasPriceData = items[2].data,
					let gasCoinData = items[3].data,
					let typeData = items[4].data,
					let txDataData = RLP.decode(items[5].data!)?.data,
					let payloadData = items[6].data,
					let serviceDataData = items[7].data,
					let signatureTypeData = items[8].data
					else {
						return nil
				}

				nonce = BigUInt(nonceData)
				chainId = BigUInt(chainIdData)
				gasPrice = BigUInt(gasPriceData)
				if let newGasCoin = String(data: gasCoinData, encoding: .utf8)?
					.replacingOccurrences(of: "\0", with: "") {
					gasCoin = newGasCoin
				}
				let typeBigInt = BigUInt(typeData)
				guard let txType = RawTransactionType.type(with: typeBigInt) else {
					return nil
				}
				type = txType
				txData = txDataData
				payload = String(data: payloadData, encoding: .utf8)
				serviceData = serviceDataData
				signatureType = signatureTypeData
			} else if items.count == 6 {//shortened version
				guard
					let typeData = items[0].data,
					let txDataData = RLP.decode(items[1].data!)!.data,
					let nonceData = items[3].data,
					let gasPriceData = items[4].data,
					let gasCoinData = items[5].data,
					let payloadData = items[2].data
					else { return nil }
				let nonceValue = BigUInt(nonceData)
				nonce = nonceValue > 0 ? nonceValue : nil

				let gasPriceValue = BigUInt(gasPriceData)
				gasPrice = gasPriceValue > 0 ? gasPriceValue : nil
				if let newGasCoin = String(data: gasCoinData, encoding: .utf8)?
					.replacingOccurrences(of: "\0", with: "") {
					gasCoin = (newGasCoin == "") ? Coin.baseCoin().symbol! : newGasCoin
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
		case .data(let data):
			break
		}
		return RawTransactionDecoderResult(
			nonce: nonce,
			chainId: chainId,
			gasPrice: gasPrice,
			gasCoin: gasCoin,
			type: type,
			txData: txData,
			payload: payload,
			serviceData: serviceData,
			signatureType: signatureType
		)
	}
}
