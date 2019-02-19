//
//  WalletCoinManager.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 09/10/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import Foundation
import Alamofire
import CryptoSwift

enum WalletCoinManagerError : Error {
	case wrongResponse
	case custom(error: String)
}

class WalletCoinManager {
	
	//MARK: -
	
	private init() {}
	
	static let shared = WalletCoinManager()
	
	//MARK: -

	func requestMNT(address: String, completion: ((WalletCoinManagerError?) -> ())?) {
		
		let signature = makeSignature(for: address)
		
		Alamofire.request("https://testnet.tgbot.minter.network/api/coins/send", method: .post, parameters: ["address" : address, "signature" : signature]).responseJSON { (response) in
			if response.response?.statusCode == 200 {
				completion?(nil)
			}
			else {
				if let result = response.value as? [String : Any], let errors = result["errors"] as? [String : Any] {
					if let firstKey = errors.keys.first, let firstKeyErrors = errors[firstKey] as? [String], let errorMessage = firstKeyErrors.first {
						completion?(WalletCoinManagerError.custom(error: errorMessage))
						return
					}
				}
				completion?(WalletCoinManagerError.wrongResponse)
			}
		}
	}
	
	private func makeSignature(for address: String) -> String {
		return address
	}

}
