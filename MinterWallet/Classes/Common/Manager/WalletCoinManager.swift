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
}

class WalletCoinManager {
	
	//MARK: -
	
	private init() {}
	
	static let shared = WalletCoinManager()
	
	//MARK: -

	func requestMNT(address: String, completion: ((Error?) -> ())?) {
		
		let signature = makeSignature(for: address)
		
		Alamofire.request("https://testnet.tgbot.minter.network/api/coins/send", method: .post, parameters: ["address" : address, "signature" : signature]).responseJSON { (response) in
			if response.response?.statusCode == 200 {
				completion?(nil)
			}
			else {
				completion?(WalletCoinManagerError.wrongResponse)
			}
		}
	}
	
	private func makeSignature(for address: String) -> String {
		return address
	}

}
