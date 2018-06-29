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


class TransactionManager {
	
	func transactions(page: Int = 0, completion: (([Transaction]?, [String : User]?, Error?) -> ())?) {
		
		let addresses = Session.shared.accounts.value.map { (account) -> String in
			return "Mx" + account.address
		}
		
		let transactionManager = MinterExplorer.TransactionManager.default
		let infoManager = MinterMy.InfoManager.default
		
		transactionManager.transactions(addresses: addresses, page: page) { (transactions, error) in
			guard nil == error else {
				return
			}
			
			let users = transactions?.map({ (transaction) -> String? in
				let from = transaction.from
				let to = transaction.to
				
				let hasAddress = Session.shared.accounts.value.contains(where: { (account) -> Bool in
					account.address.stripMinterHexPrefix().lowercased() == transaction.from?.stripMinterHexPrefix().lowercased()
				})
				
				return hasAddress ? to : from
			}).filter({ (user) -> Bool in
				return user != nil
			}) as! [String]?
			
			if (users?.count ?? 0) > 0 {
				infoManager.info(by: users!, completion: { (res, err) in
					
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
		}
	}
	
}
