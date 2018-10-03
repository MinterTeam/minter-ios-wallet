//
//  TransactionManager.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 22/06/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import Foundation
import MinterCore
import MinterMy
import MinterExplorer
import ObjectMapper


class WalletTransactionManager {
	
	
	let transactionManager = MinterExplorer.ExplorerTransactionManager.default
	let infoManager = MinterMy.InfoManager.default
	
	func transactions(addresses: [String]? = nil, page: Int = 0, completion: (([MinterExplorer.Transaction]?, [String : User]?, Error?) -> ())?) {
		
		var ads: [String]? = addresses
		if nil == ads {
			ads = Session.shared.accounts.value.map { (account) -> String in
				return "Mx" + account.address
			}
		}
		
		guard ads!.count > 0 else {
			completion?([], [:], nil)
			return
		}
		
		transactionManager.transactions(addresses: ads!, page: page) { (transactions, error) in
			guard nil == error else {
				completion?(nil, nil, error)
				return
			}

			let users = transactions?.map({ (transaction) -> String? in
				let from = transaction.data?.from
				let to = transaction.data?.to

				let hasAddress = Session.shared.accounts.value.contains(where: { (account) -> Bool in
					account.address.stripMinterHexPrefix().lowercased() == transaction.data?.from?.stripMinterHexPrefix().lowercased()
				})

				return hasAddress ? to : from
			}).filter({ (user) -> Bool in
				return user != nil
			}) as! [String]?

			if (users?.count ?? 0) > 0 {
				self.infoManager.info(by: users!, completion: { (res, err) in

					var usrs = [String : User]()

					defer {
						completion?(transactions, usrs, error)
					}

					guard err == nil else {
						return
					}

					res?.forEach({ (dict) in
						if let key = dict["address"] as? String, let userDict = dict["user"] as? [String : Any] {
							let user = User()
							user.id = userDict["id"] as? Int
							user.username = userDict["username"] as? String
							user.name = userDict["name"] as? String
							user.email = userDict["email"] as? String
							user.language = userDict["language"] as? String
							user.avatar = userDict["avatar"] as? String
							user.phone = userDict["phone"] as? String

							usrs[key.lowercased()] = user
						}
					})
				})
			}
			else {
				completion?(transactions, nil, error)
				return
			}
		}
	}
	
}
