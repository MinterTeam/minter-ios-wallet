//
//  WalletCoinManager.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 09/10/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import Foundation
import Alamofire

enum WalletCoinManagerError : Error {
	case wrongResponse
}

class WalletCoinManager {
	
	private init() {}
	
	let shared = WalletCoinManager()
	

	static func requestMNT(address: String, completion: ((Error?) -> ())?) {
		
		Alamofire.request("https://minter-bot-wallet.dl-dev.ru/api/coins/send", method: .post, parameters: ["address" : address]).responseJSON { (response) in
			if response.response?.statusCode == 200 {
				completion?(nil)
			}
			else {
				completion?(WalletCoinManagerError.wrongResponse)
			}
		}
	}

}
